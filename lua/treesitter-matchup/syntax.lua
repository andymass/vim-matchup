if not pcall(require, 'nvim-treesitter') then
  return {
    is_active = function() return false end,
    synID = function(lnum, col, transparent)
      return vim.fn.synID(lnum, col, transparent)
    end
  }
end

local api = vim.api
local hl_info = require'treesitter-matchup.third-party.hl-info'
local queries = require'treesitter-matchup.third-party.query'
local ts_utils = require'nvim-treesitter.ts_utils'

local M = {}

function M.is_active(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  return (hl_info.active()
    and api.nvim_buf_get_option(bufnr, 'syntax') == '')
end

--- Get all nodes that are marked as skip
function M.get_skips(bufnr)
  local matches = queries.get_matches(bufnr, 'matchup')

  local skips = {}

  for _, match in ipairs(matches) do
    if match.skip then
      skips[match.skip.node:id()] = 1
    end
  end

  return skips
end

function M.lang_skip(lnum, col)
  local bufnr = api.nvim_get_current_buf()
  local skips = M.get_skips(bufnr)

  if vim.tbl_isempty(skips) then
    return false
  end

  local node = ts_utils.get_node_at_cursor()
  if not node then
    return false
  end
  if skips[node:id()] then
    return true
  end

  return false
end

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
