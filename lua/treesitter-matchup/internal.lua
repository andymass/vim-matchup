local vim = vim
local api = vim.api
local ts = require 'treesitter-matchup.compat'
local queries = require 'treesitter-matchup.third-party.query'
local lru = require 'treesitter-matchup.third-party.lru'
local util = require 'treesitter-matchup.util'
local utils2 = require 'treesitter-matchup.third-party.utils'
local throttle = require 'treesitter-matchup.third-party.throttle'

local unpack = unpack or table.unpack

local M = {}

local cache = lru.new(150)
local buf_matches = {}

local active_nodes_template = function()
  return { open = {}, mid = {}, close = {} }
end

---@param bufnr number
local function clear_buf_matches(bufnr)
  buf_matches[bufnr] = nil
end

---@param bufnr number
local function get_buf_scopes(bufnr)
  return (buf_matches[bufnr] and buf_matches[bufnr].scopes) or {}
end

---@param bufnr number
local function get_buf_nodes(bufnr)
  return (buf_matches[bufnr] and buf_matches[bufnr].nodes) or active_nodes_template()
end

---@param bufnr number
local function get_buf_symbols(bufnr)
  return (buf_matches[bufnr] and buf_matches[bufnr].symbols) or {}
end

---@param bufnr number
---@return LanguageTree
local function get_buf_parser(bufnr)
  return (buf_matches[bufnr] and buf_matches[bufnr].ltree)
end

---@param bufnr number
local function get_buf_active_nodes(bufnr)
  return {
    get_buf_nodes(bufnr),
    get_buf_symbols(bufnr),
    get_buf_parser(bufnr),
  }
end

---@param bufnr number
---@return string
local function get_buf_language(bufnr)
  local parser = buf_matches[bufnr] and buf_matches[bufnr].ltree

  return (parser and parser:lang()) or
      vim.api.nvim_buf_get_option(bufnr, "ft")
end

---@param bufnr number
---@param ltree LanguageTree
---@param scopes table
---@param nodes table
---@param symbols table
local function store_buf_matches(bufnr, ltree, scopes, nodes, symbols)
  buf_matches[bufnr] = { ltree = ltree, scopes = scopes, nodes = nodes, symbols = symbols }
end

--- Returns a (mostly) unique id for this node
local function _node_id(node)
  if not node then
    return nil
  end
  if node:type() == 'nvim-treesitter-range' then
    return string.format('range_%d_%d_%d_%d', node:range())
  end
  return node:id()
end

local calculate_matches = function(bufnr, ltree)
  local matches = {}

  ltree:for_each_tree(function(tree, lang_tree)
    if not tree or lang_tree:lang() == 'comment' then
      return
    end

    local group_results = queries.collect_group_results(
      bufnr, 'matchup', tree:root(), lang_tree) or {}
    vim.list_extend(matches, group_results)
  end)


  local scopes = {}

  for _, match in ipairs(matches) do
    if match.scope then
      for key, scope in pairs(match.scope) do
        local id = _node_id(scope.node)
        if scope.node then
          if not scopes[key] then
            scopes[key] = {}
          end
          scopes[key][id] = true
        end
      end
    end
  end

  local nodes = active_nodes_template()
  local symbols = {}

  for _, match in ipairs(matches) do
    if match.open then
      for key, open in pairs(match.open) do
        local reject = key:find('quote')
            and not M.get_option(bufnr, 'enable_quotes')
        local id = _node_id(open.node)
        if not reject and open.node and symbols[id] == nil then
          table.insert(nodes.open, open.node)
          symbols[id] = key
        end
      end
    end
    if match.close then
      for key, close in pairs(match.close) do
        local reject = key:find('quote')
            and not M.get_option(bufnr, 'enable_quotes')
        local id = _node_id(close.node)
        if not reject and close.node and symbols[id] == nil then
          table.insert(nodes.close, close.node)
          symbols[id] = key
        end
      end
    end
    if match.mid then
      for key, mid_group in pairs(match.mid) do
        for _, mid in pairs(mid_group) do
          local id = _node_id(mid.node)
          if mid.node and symbols[id] == nil then
            table.insert(nodes.mid, mid.node)
            symbols[id] = key
          end
        end
      end
    end
  end

  return scopes, nodes, symbols
end

---@param bufnr number
M.register_callbacks = function(bufnr)
  local ts_parser_resolved, ltree = pcall(vim.treesitter.get_parser, bufnr)
  if not ts_parser_resolved or not ltree then
    return
  end

  if M.get_option(bufnr, 'additional_vim_regex_highlighting')
    and api.nvim_buf_get_option(bufnr, 'syntax') == '' then
    api.nvim_buf_set_option(bufnr, 'syntax', 'ON')
  end

  local get_and_store_matches = vim.schedule_wrap(function()
    vim.fn['matchup#perf#tic']('ts.calculate_matches')
    local scopes, nodes, symbols = calculate_matches(bufnr, ltree)
    vim.fn['matchup#perf#toc']('ts.calculate_matches', 'done')
    store_buf_matches(bufnr, ltree, scopes, nodes, symbols)
  end)

  local handle_updates, update_timer = throttle.throttle_leading(function()
    vim.fn['matchup#perf#tic']('ts.reparse')
    ltree:parse(true)
    vim.fn['matchup#perf#toc']('ts.reparse', 'done')
  end, 300)

  local detach = vim.schedule_wrap(function(buf)
    update_timer:stop()
    update_timer:close()
    clear_buf_matches(buf)
  end)

  ltree:register_cbs({
    on_detach = detach,
    on_bytes = handle_updates,
    on_changedtree = get_and_store_matches,
  }, true)

  ltree:parse(true)
  get_and_store_matches()

  api.nvim_buf_set_var(bufnr, 'matchup_treesitter_initialized', 1)

  return true
end

local function _time()
  local s, u = vim.loop.gettimeofday()
  return s * 1000 + u * 1e-3
end

local function containing_scope(node, bufnr, key)
  bufnr = bufnr or api.nvim_get_current_buf()

  local scopes = get_buf_scopes(bufnr)
  if not node or not scopes or not scopes[key] then return end

  local iter_node = node

  while iter_node ~= nil do
    if scopes[key][_node_id(iter_node)] then
      return iter_node
    end
    iter_node = iter_node:parent()
  end

  return nil
end

local function _node_text(node, bufnr)
  local text = ts.get_node_text(node, bufnr)
  return text:match("(%S+).*") or ""
end

--- Fill in a match result based on a seed node
local function do_node_result(initial_node, bufnr, opts, side, key)
  if not side or not key then
    return nil
  end

  local scope = containing_scope(initial_node, bufnr, key)
  if not scope then
    return nil
  end

  local row, col, _ = initial_node:start()

  local result = {
    type = 'delim_py',
    match = _node_text(initial_node, bufnr),
    side = side,
    lnum = row + 1,
    cnum = col + 1,
    skip = 0,
    class = { key, 0 },
    highlighting = opts['highlighting'],
    _id = util.uuid4(),
  }

  local info = {
    bufnr = bufnr,
    initial_node = initial_node,
    row = row,
    col = col,
    key = key,
    scope = scope,
    search_range = { scope:range() },
  }

  cache:set(result._id, info)

  return result
end

local side_table = {
  open     = { 'open' },
  mid      = { 'mid' },
  close    = { 'close' },
  both     = { 'close', 'open' },
  both_all = { 'close', 'mid', 'open' },
  open_mid = { 'mid', 'open' },
}

function M.get_delim(bufnr, opts)
  -- get current by query
  local active_nodes, symbols = unpack(get_buf_active_nodes(bufnr))
  local cursor = api.nvim_win_get_cursor(0)

  if opts.direction == 'current' then
    local smallest_len = 1e31
    local result_info = nil
    for _, side in ipairs(side_table[opts.side]) do
      if not (side == 'mid' and vim.g.matchup_delim_nomids > 0) then
        for _, node in ipairs(active_nodes[side]) do
          if utils2.is_in_node_range(node, cursor[1] - 1, cursor[2]) then
            local len = utils2.node_length(node)
            if len < smallest_len then
              smallest_len = len
              result_info = {
                node = node,
                side = side,
                key = symbols[_node_id(node)]
              }
            end
          end
        end
      end
    end

    if result_info then
      return do_node_result(result_info.node, bufnr, opts,
        result_info.side, result_info.key)
    end

    return
  end

  -- direction is next or prev
  -- look forwards or backwards for an active node
  local max_col = 1e5

  local cur_pos = max_col * (cursor[1] - 1) + cursor[2]
  local closest_node, closest_dist = nil, 1e31
  local result_info = {}

  for _, side in ipairs(side_table[opts.side]) do
    for _, node in ipairs(active_nodes[side]) do
      local row, col, _ = node:start()
      local pos = max_col * row + col

      if opts.direction == 'next' and pos >= cur_pos
          or opts.direction == 'prev' and pos <= cur_pos then
        local dist = math.abs(pos - cur_pos)
        if dist < closest_dist then
          closest_dist = dist
          closest_node = node
          result_info = { side = side, key = symbols[_node_id(node)] }
        end
      end
    end
  end

  if closest_node == nil then
    return nil
  end

  return do_node_result(closest_node, bufnr, opts,
    result_info.side, result_info.key)
end

function M.get_matching(delim, down, bufnr)
  down = down > 0

  local info = cache:get(delim._id) or {}
  if info.bufnr ~= bufnr then
    return {}
  end

  local matches = {}

  local sides
  if vim.g.matchup_delim_nomids > 0 then
    sides = down and { 'close' } or { 'open' }
  else
    sides = down and { 'mid', 'close' } or { 'mid', 'open' }
  end

  local active_nodes, symbols, parser = unpack(get_buf_active_nodes(bufnr))

  -- parser needs validation, skip processing
  if not parser:is_valid() then
    return matches
  end

  local got_close = false

  local stop_time = _time() + vim.fn['matchup#perf#timeout']()

  for _, side in ipairs(sides) do
    for _, node in ipairs(active_nodes[side]) do
      local row, col, _ = node:start()

      if _time() > stop_time then
        return {}
      end

      if info.initial_node ~= node and symbols[_node_id(node)] == info.key
          and (down and (row > info.row or row == info.row and col > info.col)
            or not down and (row < info.row or row == info.row and col < info.col))
          and (row >= info.search_range[1]
            and row <= info.search_range[3]) then
        local target_scope = containing_scope(node, bufnr, info.key)
        if info.scope == target_scope then
          local text = _node_text(node, bufnr) or ''
          table.insert(matches, { text, row + 1, col + 1 })

          if side == 'close' then
            got_close = true
          end
        end
      end
    end
  end

  -- sort by position
  table.sort(matches, function(a, b)
    return a[2] < b[2] or a[2] == b[2] and a[3] < b[3]
  end)

  -- no stop marker is found, use enclosing scope
  if down and not got_close then
    local row, col, _ = info.scope:end_()
    table.insert(matches, { '', row + 1, col + 1 })
  end

  return matches
end

local function opt_tbl_for_lang(opt, lang)
  local is_table = type(opt) == "table"
  if opt and (not is_table or vim.tbl_contains(opt, lang)) then
    return true
  end
  return false
end

function M.get_option(bufnr, opt_name)
  local config = vim.g.matchup_treesitter_config or {}
  local lang = get_buf_language(bufnr)

  if (opt_name == 'include_match_words'
        or opt_name == 'additional_vim_regex_highlighting'
        or opt_name == 'disable_virtual_text'
        or opt_name == 'enable_quotes') then
    return opt_tbl_for_lang(config[opt_name], lang)
  end
  error('invalid option ' .. opt_name)
end

function M.attach(bufnr, lang)
  vim.deprecate("matchup treesitter module", "vim.g.matchup_treesitter_config", "in the future", "vim-matchup")
end

function M.detach(bufnr)
end

return M

