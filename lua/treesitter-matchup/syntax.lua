local api = vim.api
local vts = vim.treesitter
local hl_info = require'treesitter-matchup.third-party.hl-info'
local internal = require'treesitter-matchup.internal'
local unpack = unpack or table.unpack

local M = {}

---@param bufnr integer?
---@return boolean
function M.is_active(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  return (hl_info.active()
    and vim.bo[bufnr].syntax == '')
end

---@param bufnr integer
---@return table<string, true>
local function query_skips(bufnr)
  local matches = internal.get_matches(bufnr)

  local skips = {} ---@type table<string, true>
  for _, match in ipairs(matches) do
    if match.type == 'skip' then
      local id = ('range_%d_%d_%d_%d'):format(unpack(match.range))
      skips[id] = true
    end
  end

  return skips
end

--- The skip nodes found by the last query, with what they depend on
---@class matchup.treesitter.SkipCache
---@field bufnr integer
---@field tick integer
---@field lang string
---@field query vim.treesitter.Query?
---@field start_row integer
---@field end_row integer
---@field skips table<string, true>
local cache ---@type matchup.treesitter.SkipCache?

--- The language, and its query, that get_matches starts from at the cursor
---@param bufnr integer
---@param cursor integer[]
---@return string?
---@return vim.treesitter.Query?
local function get_cursor_lang(bufnr, cursor)
  local lang_tree = vts.get_parser(bufnr, nil, { error = false })
  if not lang_tree then
    return nil
  end

  local row, col = cursor[1] - 1, cursor[2]
  local lang = lang_tree:language_for_range({ row, col, row, col }):lang()
  return lang, vts.query.get(lang, 'matchup')
end

--- Get all nodes that are marked as skip
---
--- Searching for a match calls this for every candidate delimiter, with
--- the cursor on it, so the result is reused as long as the buffer and
--- query are unchanged and the cursor is still in the rows it was
--- computed from.
---@param bufnr integer
---@return table<string, true>
function M.get_skips(bufnr)
  local cursor = api.nvim_win_get_cursor(0)
  local lang, query = get_cursor_lang(bufnr, cursor)
  if not lang then
    return query_skips(bufnr)
  end

  local tick = api.nvim_buf_get_changedtick(bufnr)
  local row = cursor[1] - 1
  if cache
      and cache.bufnr == bufnr
      and cache.tick == tick
      and cache.lang == lang
      and cache.query == query
      and row >= cache.start_row
      and row < cache.end_row then
    return cache.skips
  end

  local start_row, end_row = internal.get_query_range(bufnr, cursor)
  cache = {
    bufnr = bufnr,
    tick = tick,
    lang = lang,
    query = query,
    start_row = start_row,
    end_row = end_row,
    skips = query_skips(bufnr),
  }
  return cache.skips
end

---@param lnum integer
---@param col integer
---@return boolean
function M.lang_skip(lnum, col)
  local bufnr = api.nvim_get_current_buf()
  local skips = M.get_skips(bufnr)

  if vim.tbl_isempty(skips) then
    return false
  end

  local success, node = pcall(vts.get_node, {pos = {lnum - 1, col - 1}})
  if not success or not node then
    return false
  end
  local id = ('range_%d_%d_%d_%d'):format(node:range())
  if skips[id] then
    return true
  end

  return false
end

---@param lnum integer
---@param col integer
---@param transparent 1|0
function M.synID(lnum, col, transparent)
  if not M.is_active() then
    return vim.fn.synID(lnum, col, transparent)
  end

  local cursor = { lnum, col - 1 }
  local matches = hl_info.get_treesitter_hl(cursor)
  if #matches < 1 then
    return 0
  end

  -- heuristically get the last group with any hl definitions
  for i = 1, #matches do
    local group = matches[#matches + 1 - i]
    group = group[#group]

    local id = vim.fn.hlID(group)
    local trans_id = vim.fn.synIDtrans(id)
    if vim.fn.synIDattr(trans_id, 'fg') ~= ''
        or vim.fn.synIDattr(trans_id, 'fg') ~= '' then
      return id
    end
  end

  return 0
end

return M
