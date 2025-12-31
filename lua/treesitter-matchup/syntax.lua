local api = vim.api
local vts = vim.treesitter
local hl_info = require'treesitter-matchup.third-party.hl-info'
local internal = require'treesitter-matchup.internal'

local M = {}

---@param bufnr integer?
---@return boolean
function M.is_active(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  return (hl_info.active()
    and vim.bo[bufnr].syntax == '')
end

--- Get all nodes that are marked as skip
---@param bufnr integer
function M.get_skips(bufnr)
  local matches = internal.get_matches(bufnr)

  local skips = {} ---@type table<string, 1>

  for _, match in ipairs(matches) do
    if match.skip then
      skips[internal.range_id(match.skip.info.range)] = 1
    end
  end

  return skips
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
  ---@diagnostic disable-next-line: missing-fields LuaLS bug
  if skips[internal.range_id({node:range()})] then
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
