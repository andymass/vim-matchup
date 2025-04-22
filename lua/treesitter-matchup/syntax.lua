local api = vim.api
local hl_info = require 'treesitter-matchup.third-party.hl-info'
local get_parser = require 'treesitter-matchup.get_parser'

local M = {}

function M.is_active(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  return (hl_info.active()
    and api.nvim_buf_get_option(bufnr, 'syntax') == '')
end

--- Get all nodes that are marked as skip
function M.get_skips(bufnr, lnum_0, col_0)
  assert(bufnr)

  local skips = {}

  local parser, _ = get_parser(bufnr, nil, { error = false })
  -- Parser unknown (either unknown language or no such parser)
  if not parser then return skips end

  local position_range = { lnum_0, col_0, lnum_0, col_0 } ---@type Range4
  parser:parse(position_range)
  local position_ltree = parser:language_for_range(position_range)
  local query = vim.treesitter.query.get(
    position_ltree:lang(),
    "matchup"
  )

  -- No query found
  if not query then return skips end

  local position_tsroot = position_ltree:named_node_for_range(position_range):tree():root()
  for _, match, _ in query:iter_matches(position_tsroot, bufnr) do
    for id, nodes in pairs(match) do
      local name = query.captures[id]
      if name == "skip" then
        for _, node in ipairs(nodes) do
          -- `node` was captured by the `name` (skip) capture in the match
          skips[node:id()] = 1
          -- ... use the info here ...
        end
      end
    end
  end

  return skips
end

function M.lang_skip(lnum, col)
  local bufnr = api.nvim_get_current_buf()
  local skips = M.get_skips(bufnr, lnum - 1, col - 1)

  if vim.tbl_isempty(skips) then
    return false
  end

  local node = vim.treesitter.get_node({ pos = { lnum - 1, col - 1 } })
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
