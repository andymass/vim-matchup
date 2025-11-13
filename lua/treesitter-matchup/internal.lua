local vim = vim
local api = vim.api
local ts = vim.treesitter
local memoize = require'treesitter-matchup.third-party.ts-utils'.memoize

local lru = require'treesitter-matchup.third-party.lru'
local util = require'treesitter-matchup.util'

local unpack = unpack or table.unpack

local M = {}

local cache = lru.new(150)


---@param lang string
---@param bufnr integer
local function is_enabled(lang, bufnr)
  local enabled = vim.g.matchup_treesitter_enabled
  local buf_enabled = vim.b[bufnr].matchup_treesitter_enabled
  local lang_disabled = vim.list_contains(vim.g.matchup_treesitter_disabled, lang)

  if buf_enabled == false then
    return false
  end

  return enabled and not lang_disabled
end

---@param bufnr integer?
---@return boolean
function M.is_enabled(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  if not api.nvim_buf_is_loaded(bufnr) then
    return false
  end
  local lang = ts.language.get_lang(vim.bo[bufnr].filetype)
  if not lang then
    return false
  end
  local _, err = ts.get_parser(bufnr, nil, {error = false})
  if err then
    return false
  end
  local queries = ts.query.get_files(lang, "matchup")
  if vim.tbl_isempty(queries) then
    return false
  end
  return is_enabled(lang, bufnr)
end

---@param bufnr integer
---@param root TSNode
---@param lang string
---@return string
local function buf_root_lang_hash(bufnr, root, lang)
  return tostring(bufnr) .. root:id() .. '_' .. lang
end

---@class matchup.treesitter.MatchInfo
---@field range Range4
---@field length integer
---@field last_node TSNode
---@field text string

---@class matchup.treesitter.MatchInfoWrapper
---@field info matchup.treesitter.MatchInfo

---@class matchup.treesitter.Match
---@field scope? table<string, matchup.treesitter.MatchInfoWrapper>
---@field open? table<string, matchup.treesitter.MatchInfoWrapper>
---@field mid? table<string, table<string, matchup.treesitter.MatchInfoWrapper>>
---@field close? table<string, matchup.treesitter.MatchInfoWrapper>
---@field skip? matchup.treesitter.MatchInfoWrapper

---@param bufnr integer
---@param root TSNode
---@param lang string
---@return matchup.treesitter.Match[]
local get_memoized_matches = memoize(function(bufnr, root, lang)
  local query = ts.query.get(lang, 'matchup')

  if not query then
    return {}
  end

  local out = {} ---@type matchup.treesitter.Match[]
  for _, match, metadata in query:iter_matches(root, bufnr) do
    local match_info = {}
    for id, nodes in pairs(match) do
      local first = nodes[1]
      local last = nodes[#nodes]

      ---@type integer, integer, integer
      local start_row, start_col , start_byte = unpack(ts.get_range(first, bufnr, metadata))
      ---@type integer, integer, integer, integer, integer, integer
      local _, _, _, end_row, end_col , end_byte = unpack(ts.get_range(last, bufnr, metadata))
      local range = { start_row, start_col, end_row, end_col }
      local length =  end_byte - start_byte

      if end_col == 0 then
        if start_row == end_row then
          start_col = -1
          start_row = start_row - 1
        end
        end_col = -1
        end_row = end_row - 1
      end
      local lines = api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
      local text = table.concat(lines, '\n')

      local name = query.captures[id]
      local path = {} ---@type string[]
      for part in name:gmatch('[^.]+') do
        table.insert(path, part)
      end

      local current = match_info ---@type table<string, table<string, matchup.treesitter.MatchInfo>>
      for _, segment in ipairs(path) do
        current[segment] = current[segment] or {}
        current = current[segment]
      end
      current.info = {
        range = range,
        length = length,
        last_node = last,
        text = text,
      }
    end
    table.insert(out, match_info)
  end

  return out
end, buf_root_lang_hash)

---@param bufnr integer
---@return matchup.treesitter.Match[]
M.get_matches = function(bufnr)
  local lang_tree = ts.get_parser(bufnr)
  local matches = {} ---@type matchup.treesitter.Match[]

  if lang_tree then
    -- NOTE: assummes that we are always parsing the current window. May cause
    -- issues if that's not always the case
    local cursor = vim.api.nvim_win_get_cursor(0)
    local stopline = vim.g.matchup_treesitter_stopline ---@type integer
    local start_row = math.max(cursor[1] - stopline, 0)
    local end_row = math.min(cursor[1] + stopline, api.nvim_buf_line_count(bufnr))

    lang_tree:parse({ start_row, end_row })
    ---@type vim.treesitter.LanguageTree?
    local nested_lang_tree = lang_tree:language_for_range({ cursor[1]-1, cursor[2], cursor[1]-1, cursor[2] })
    while vim.tbl_isempty(matches) and nested_lang_tree ~= nil do
      local lang = nested_lang_tree:lang()
      if lang ~= 'comment' then
        for _, tree in ipairs(nested_lang_tree:trees()) do
          local group_results = get_memoized_matches(bufnr, tree:root(), lang)
          vim.list_extend(matches, group_results)
        end
      end

      nested_lang_tree = nested_lang_tree:parent()
    end
  end

  return matches
end

local function _time()
  local s, u = vim.uv.gettimeofday()
  return s * 1000 + u * 1e-3
end

--- Returns a (mostly) unique id for this range
---@param range Range4
---@return string
function M.range_id(range)
  return ('range_%d_%d_%d_%d'):format(unpack(range))
end

--- Get all nodes belonging to defined scopes (organized by key)
---@param bufnr integer
---@return table<string, table<string, boolean>>
M.get_scopes = function(bufnr)
  local matches = M.get_matches(bufnr)

  local scopes = {} ---@type table<string, table<string, boolean>>

  for _, match in ipairs(matches) do
    if match.scope then
      for key, scope in pairs(match.scope) do
        if scope.info then
          local id = M.range_id(scope.info.range)
          scopes[key] = scopes[key] or {}
          scopes[key][id] = true
        end
      end
    end
  end

  return scopes
end

---@class matchup.treesitter.Matches
---@field open matchup.treesitter.MatchInfo[]
---@field mid matchup.treesitter.MatchInfo[]
---@field close matchup.treesitter.MatchInfo[]

---@param bufnr integer
---@return [matchup.treesitter.Matches, table<string, string>]
M.get_active_matches = function(bufnr)
  local matches = M.get_matches(bufnr)

  ---@type matchup.treesitter.Matches
  local info = { open = {}, mid = {}, close = {} }
  ---@type table<string, string>
  local symbols = {}

  local enable_quotes = vim.g.matchup_treesitter_enable_quotes
  for _, match in ipairs(matches) do
    if match.open then
      for key, open in pairs(match.open) do
        local reject = key:find('quote') and not enable_quotes
        local id = M.range_id(open.info.range)
        if not reject and open.info and symbols[id] == nil then
          table.insert(info.open, open.info)
          symbols[id] = key
        end
      end
    end
    if match.close then
      for key, close in pairs(match.close) do
        local reject = key:find('quote') and not enable_quotes
        local id = M.range_id(close.info.range)
        if not reject and close.info and symbols[id] == nil then
          table.insert(info.close, close.info)
          symbols[id] = key
        end
      end
    end
    if match.mid then
      for key, mid_group in pairs(match.mid) do
        for _, mid in pairs(mid_group) do
          local id = M.range_id(mid.info.range)
          if mid.info and symbols[id] == nil then
            table.insert(info.mid, mid.info)
            symbols[id] = key
          end
        end
      end
    end
  end

  return {info, symbols}
end

---@param info matchup.treesitter.MatchInfo?
---@param bufnr integer?
---@param key string
---@return TSNode|nil
function M.containing_scope(info, bufnr, key)
  bufnr = bufnr or api.nvim_get_current_buf()

  local scopes = M.get_scopes(bufnr)
  if not info or not scopes or not scopes[key] then return end

  ---@type TSNode|nil
  local iter_node = info.last_node

  while iter_node ~= nil do
    ---@diagnostic disable-next-line: missing-fields LuaLS bug
    if scopes[key][M.range_id({iter_node:range()})] then
      return iter_node
    end
    iter_node = iter_node:parent()
  end

  return nil
end

---@param info matchup.treesitter.MatchInfo
---@return string
local function text_until_newline(info)
  local text = info.text
  return text:match("([^\n]+).*")
end

--- Fill in a match result based on a seed node
---@param info matchup.treesitter.MatchInfo
---@param bufnr integer
---@param opts table<string, unknown>
---@param side matchup.Side?
---@param key string?
function M.do_match_result(info, bufnr, opts, side, key)
  if not side or not key then
    return nil
  end

  local scope = M.containing_scope(info, bufnr, key)
  if not scope then
    return nil
  end

  ---@type integer, integer
  local row, col = unpack(info.range)

  ---@class matchup.Delim
  local result = {
    type = 'delim_py',
    match = text_until_newline(info),
    side = side,
    lnum = row + 1,
    cnum = col + 1,
    skip = 0,
    class = {key, 0},
    highlighting = opts['highlighting'],
    _id = util.uuid4(),
  }

  local cached_info = {
    bufnr = bufnr,
    info = info,
    row = row,
    col = col,
    key = key,
    scope = scope,
    search_range = {scope:range()},
  }

  cache:set(result._id, cached_info)

  return result
end

---@param info matchup.treesitter.MatchInfo
---@param line integer
---@param col integer
---@return boolean
local function is_in_range(info, line, col)
  ---@type integer, integer, integer, integer
  local r_start_row, r_start_col, r_end_row, r_end_col = unpack(info.range)
  local p_start_row, p_start_col, p_end_row, p_end_col = line, col, line, col + 1

  if p_start_row < r_start_row then
    return false
  elseif p_start_row == r_start_row and p_start_col < r_start_col  then
    return false
  end

  if p_end_row > r_end_row then
    return false
  elseif p_end_row == r_end_row and p_end_col > r_end_col then
    return false
  end

  return true
end

---@type table<matchup.Side, ('open'|'mid'|'close')[]>
local side_table = {
  open     = {'open'},
  mid      = {'mid'},
  close    = {'close'},
  both     = {'close', 'open'},
  both_all = {'close', 'mid', 'open'},
  open_mid = {'mid', 'open'},
}

---@alias matchup.Side 'open'|'mid'|'close'|'both'|'both_all'|'open_mid'
---@alias matchup.Direction 'current'|'next'|'prev'
---@alias matchup.Type 'delim_text'|'delim_all'|'all'

---@param bufnr integer
---@param opts {direction: matchup.Direction, side: matchup.Side, type: matchup.Type}
function M.get_delim(bufnr, opts)
  if opts.direction == 'current' then
    -- get current by query
    local active_matches, symbols = unpack(M.get_active_matches(bufnr))
    local cursor = api.nvim_win_get_cursor(0)

    local smallest_len = 1e31
    ---@type {info: matchup.treesitter.MatchInfo, side: matchup.Side, key: string}|nil
    local result_info = nil
    for _, side in ipairs(side_table[opts.side]) do
      if not(side == 'mid' and vim.g.matchup_delim_nomids > 0) then
        for _, info in ipairs(active_matches[side] --[=[@as matchup.treesitter.MatchInfo[]]=]) do
          if is_in_range(info, cursor[1] - 1, cursor[2]) then
            local len = info.length
            if len < smallest_len then
              smallest_len = len
              result_info = {
                info = info,
                side = side,
                key = symbols[M.range_id(info.range)]
              }
            end
          end
        end
      end
    end

    if result_info then
      return M.do_match_result(result_info.info, bufnr, opts,
        result_info.side, result_info.key)
    end

    return
  end

  -- direction is next or prev
  -- look forwards or backwards for an active node
  local max_col = 1e5

  local active_matches, symbols = unpack(M.get_active_matches(bufnr))

  local cursor = api.nvim_win_get_cursor(0)
  local cur_pos = max_col * (cursor[1]-1) + cursor[2]
  local closest_match, closest_dist = nil, 1e31
  local result_info = {}

  for _, side in ipairs(side_table[opts.side]) do
    for _, info in ipairs(active_matches[side]--[=[@as matchup.treesitter.MatchInfo[]]=]) do
      ---@type integer, integer
      local row, col = unpack(info.range)
      local pos = max_col * row + col

      if opts.direction == 'next' and pos >= cur_pos
        or opts.direction == 'prev' and pos <= cur_pos then

        local dist = math.abs(pos - cur_pos)
        if dist < closest_dist then
          closest_dist = dist
          closest_match = info
          result_info = { side=side, key=symbols[M.range_id(info.range)] }
        end
      end
    end
  end

  if closest_match == nil then
    return nil
  end

  return M.do_match_result(closest_match, bufnr, opts,
    result_info.side, result_info.key)
end

---@param delim matchup.Delim
---@param down 1|0
---@param bufnr integer
---@return [string, integer, integer][]
function M.get_matching(delim, down, bufnr)
  local is_down = down > 0

  local cached_info = cache:get(delim._id) or {}
  if cached_info.bufnr ~= bufnr then
    return {}
  end

  local matches = {} ---@type [string, integer, integer][]

  local sides ---@type ('open'|'mid'|'close')[]
  if vim.g.matchup_delim_nomids > 0 then
    sides = is_down and {'close'} or {'open'}
  else
    sides = is_down and {'mid', 'close'} or {'mid', 'open'}
  end

  local active_matches, symbols = unpack(M.get_active_matches(bufnr))

  local got_close = false

  local stop_time = _time() + vim.fn['matchup#perf#timeout']() ---@type number

  for _, side in ipairs(sides) do
    for _, info in ipairs(active_matches[side]--[=[@as matchup.treesitter.MatchInfo[]]=]) do
      ---@type integer, integer
      local row, col = unpack(info.range)

      if _time() > stop_time then
        return {}
      end

      if cached_info.info ~= info and symbols[M.range_id(info.range)] == cached_info.key
          and (is_down and (row > cached_info.row or row == cached_info.row and col > cached_info.col)
            or not is_down and (row < cached_info.row or row == cached_info.row and col < cached_info.col))
          and (row >= cached_info.search_range[1]
            and row <= cached_info.search_range[3]) then

        local target_scope = M.containing_scope(info, bufnr, cached_info.key)
        if cached_info.scope == target_scope then
          local text = text_until_newline(info) or ''
          table.insert(matches, {text, row + 1, col + 1})

          if side == 'close' then
            got_close = true
          end
        end
      end
    end
  end

  -- sort by position
  table.sort(matches, function (a, b)
    return a[2] < b[2] or a[2] == b[2] and a[3] < b[3]
  end)

  -- no stop marker is found, use enclosing scope
  if is_down and not got_close then
    local row, col, _ = cached_info.scope:end_()
    table.insert(matches, {'', row + 1, col + 1})
  end

  return matches
end

return M
