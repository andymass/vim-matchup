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
local parsers = require'nvim-treesitter.parsers'

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

local function get_node_at_pos(cursor)
  local cursor_range = { cursor[1] - 1, cursor[2] }

  local buf = vim.api.nvim_win_get_buf(0)
  local root_lang_tree = parsers.get_parser(buf)
  if not root_lang_tree then
    return
  end
  local root = ts_utils.get_root_for_position(
    cursor_range[1], cursor_range[2], root_lang_tree)

  if not root then
    return
  end

  return root:named_descendant_for_range(
    cursor_range[1], cursor_range[2], cursor_range[1], cursor_range[2])
end

function M.lang_skip(lnum, col)
  local bufnr = api.nvim_get_current_buf()
  local skips = M.get_skips(bufnr)

  if vim.tbl_isempty(skips) then
    return false
  end

  local node = get_node_at_pos({lnum, col - 1})
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
