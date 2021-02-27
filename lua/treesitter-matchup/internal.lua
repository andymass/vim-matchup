if not pcall(require, 'nvim-treesitter') then
  return {is_enabled = function(bufnr) return 0 end}
end

local vim = vim
local api = vim.api
local configs = require'nvim-treesitter.configs'
local locals = require'nvim-treesitter.locals'
local parsers = require'nvim-treesitter.parsers'
local queries = require'nvim-treesitter.query'
local ts_utils = require'nvim-treesitter.ts_utils'
local lru = require'treesitter-matchup.lru'
local util = require'treesitter-matchup.util'

local M = {}

local cache = lru.new(20)

function M.is_enabled(bufnr)
  local buf = bufnr or api.nvim_get_current_buf()
  local lang = parsers.get_buf_lang(buf)
  return configs.is_enabled('matchup', lang)
end

function M.get_matches(bufnr)
  return queries.get_matches(bufnr, 'matchup')
end

function M.get_scopes(bufnr)
  local matches = M.get_matches(bufnr)

  local scopes = {}

  for _, match in ipairs(matches) do
    if match.scope then
      for key, scope in pairs(match.scope) do
        if scope.node then
          if not scopes[key] then
            scopes[key] = {}
          end
          table.insert(scopes[key], scope.node)
        end
      end
    end
  end

  return scopes
end

function M.get_active_nodes(bufnr)
  local matches = M.get_matches(bufnr)

  local nodes = { open = {}, mid = {}, close = {} }
  local symbols = {}

  for _, match in ipairs(matches) do
    if match.open then
      for key, open in pairs(match.open) do
        if open.node and symbols[open.node:id()] == nil then
          table.insert(nodes.open, open.node)
          symbols[open.node:id()] = key
        end
      end
    end
    if match.close then
      for key, close in pairs(match.close) do
        if close.node and symbols[close.node:id()] == nil then
          table.insert(nodes.close, close.node)
          symbols[close.node:id()] = key
        end
      end
    end
    if match.mid then
      for key, mid_group in pairs(match.mid) do
        for _, mid in pairs(mid_group) do
          if mid.node and symbols[mid.node:id()] == nil then
            table.insert(nodes.mid, mid.node)
            symbols[mid.node:id()] = key
          end
        end
      end
    end
  end

  return nodes, symbols
end

function M.containing_scope(node, bufnr, key)
  local bufnr = bufnr or api.nvim_get_current_buf()

  local scopes = M.get_scopes(bufnr)
  if not node or not scopes then return end

  local iter_node = node

  while iter_node ~= nil do
    if scopes[key] and vim.tbl_contains(scopes[key], iter_node) then
      return iter_node
    end
    iter_node = iter_node:parent()
  end

  return nil
end

function M.active_node(node, bufnr)
  local bufnr = bufnr or api.nvim_get_current_buf()

  local scopes, symbols = M.get_active_nodes(bufnr)
  if not node or not scopes then return end

  local iter_node = node

  while iter_node ~= nil do
    for side, _ in pairs(scopes) do
      if vim.tbl_contains(scopes[side], iter_node) then
        return iter_node, side, symbols[iter_node:id()]
      end
    end
    iter_node = iter_node:parent()
  end

  return nil
end

function M.get_node_at_cursor(winnr)
  if not parsers.has_parser() then return end
  local cursor = api.nvim_win_get_cursor(winnr or 0)
  local root = parsers.get_parser():parse()[1]:root()
  return root:descendant_for_range(cursor[1]-1, cursor[2],
    cursor[1]-1, cursor[2])
end

function M.do_node_result(initial_node, bufnr, opts)
  local node, side, key = M.active_node(initial_node, bufnr)
  if not side then
    return nil
  end

  local scope = M.containing_scope(initial_node, bufnr, key)
  if not scope then
    return nil
  end


  row, col, _ = initial_node:start()

  local result = {
    type = 'delim_py',
    match = ts_utils.get_node_text(initial_node, bufnr)[1],
    side = side,
    lnum = row + 1,
    cnum = col + 1,
    skip = 0,
    class = {key, 0},
    highlighting = opts['highlighting'],
    _id = util.uuid4(),
  }

  local info = {
    bufnr = bufnr,
    initial_node = initial_node,
    row = row,
    key = key,
    scope = scope,
    search_range = {scope:range()},
  }

  cache:set(result._id, info)

  return result
end

local side_table = {
  open     = {'open'},
  mid      = {'mid'},
  close    = {'close'},
  both     = {'close', 'open'},
  both_all = {'close', 'mid', 'open'},
  open_mid = {'mid', 'open'},
}

function M.get_delim(bufnr, opts)
  if opts.direction == 'current' then
    local node_at_cursor = M.get_node_at_cursor()

    if node_at_cursor:named() then
      return nil
    end

    return M.do_node_result(node_at_cursor, bufnr, opts)
  end

  -- direction is next or prev
  local active_nodes = M.get_active_nodes(bufnr)

  local cursor = api.nvim_win_get_cursor(0)
  local cur_pos = 1e5 * (cursor[1]-1) + cursor[2]
  local closest_node, closest_dist = nil, 1e31

  for _, side in ipairs(side_table[opts.side]) do
    for _, node in ipairs(active_nodes[side]) do
      local row, col, _ = node:start()
      local pos = 1e5 * row + col

      if opts.direction == 'next' and pos >= cur_pos
        or opts.direction == 'prev' and pos <= cur_pos then

        dist = math.abs(pos - cur_pos)
        if dist < closest_dist then
          closest_dist = dist
          closest_node = node
        end
      end

    end
  end

  if closest_node == nil then
    return nil
  end

  return M.do_node_result(closest_node, bufnr, opts)

end

function M.get_matching(delim, down, bufnr)
  down = down > 0

  local info = cache:get(delim._id)
  if info.bufnr ~= bufnr then
    return {}
  end

  local matches = {}

  local sides = down and {'mid', 'close'} or {'mid', 'open'}
  local active_nodes, symbols = M.get_active_nodes(bufnr)

  local got_close = false

  for _, side in ipairs(sides) do
    for _, node in ipairs(active_nodes[side]) do
      local row, col, _ = node:start()
      if info.initial_node ~= node and symbols[node:id()] == info.key
          and (down and row >= info.row
            or not down and row <= info.row)
          and (row >= info.search_range[1]
            and row <= info.search_range[3]) then

        local scope = M.containing_scope(node, bufnr, info.key)

        local text = ts_utils.get_node_text(node, bufnr)[1]
        table.insert(matches, {text, row + 1, col + 1})

        if side == 'close' then
          got_close = true
        end
      end
    end
  end

  -- sort by position
  table.sort(matches, function (a, b)
    return a[2] < b[2] or a[2] == b[2] and a[3] < b[3]
  end)

  -- no stop marker is found, use enclosing scope
  if down and not got_close then
    row, col, _ = info.scope:end_()
    table.insert(matches, {'', row + 1, col + 1})
  end

  return matches
end

function M.attach(bufnr, lang)
  api.nvim_call_function('matchup#ts_engine#attach', {bufnr, lang})
end

function M.detach(bufnr)
  api.nvim_call_function('matchup#ts_engine#detach', {bufnr})
end

return M
