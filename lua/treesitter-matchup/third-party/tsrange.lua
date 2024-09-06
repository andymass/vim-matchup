-- From https://github.com/nvim-treesitter/nvim-treesitter
-- Copyright 2021
-- licensed under the Apache License 2.0
-- See nvim-treesitter.LICENSE-APACHE-2.0

local M = {}
local TSRange = {}
TSRange.__index = TSRange

local api = vim.api

local function get_byte_offset(buf, row, col)
  return api.nvim_buf_get_offset(buf, row) + vim.fn.byteidx(api.nvim_buf_get_lines(buf, row, row + 1, false)[1], col)
end

function TSRange.new(buf, start_row, start_col, end_row, end_col)
  return setmetatable({
    start_pos = { start_row, start_col, get_byte_offset(buf, start_row, start_col) },
    end_pos = { end_row, end_col, get_byte_offset(buf, end_row, end_col) },
    buf = buf,
    [1] = start_row,
    [2] = start_col,
    [3] = end_row,
    [4] = end_col,
  }, TSRange)
end

function TSRange.from_nodes(buf, start_node, end_node)
  TSRange.__index = TSRange
  local start_pos = start_node and { start_node:start() } or { end_node:start() }
  local end_pos = end_node and { end_node:end_() } or { start_node:end_() }
  return setmetatable({
    start_pos = { start_pos[1], start_pos[2], start_pos[3] },
    end_pos = { end_pos[1], end_pos[2], end_pos[3] },
    buf = buf,
    [1] = start_pos[1],
    [2] = start_pos[2],
    [3] = end_pos[1],
    [4] = end_pos[2],
  }, TSRange)
end

function TSRange.from_table(buf, range)
  return setmetatable({
    start_pos = { range[1], range[2], get_byte_offset(buf, range[1], range[2]) },
    end_pos = { range[3], range[4], get_byte_offset(buf, range[3], range[4]) },
    buf = buf,
    [1] = range[1],
    [2] = range[2],
    [3] = range[3],
    [4] = range[4],
  }, TSRange)
end

function TSRange:parent()
  local lang_tree_found, lang_tree = pcall(vim.treesitter.get_parser, self.buf)
  if not lang_tree_found or not lang_tree then
    return
  end

  local root
  for _, tree in pairs(lang_tree:trees()) do
    root = tree:root()

    if root and vim.treesitter.is_in_node_range(root, self[1], self[2]) then
      break
    end
  end

  return root
      and root:named_descendant_for_range(self.start_pos[1], self.start_pos[2], self.end_pos[1], self.end_pos[2])
      or nil
end

function TSRange:range()
  return self.start_pos[1], self.start_pos[2], self.end_pos[1], self.end_pos[2]
end

function TSRange:type()
  return "nvim-treesitter-range"
end

function TSRange:start()
  return unpack(self.start_pos)
end

function TSRange:end_()
  return unpack(self.end_pos)
end

M.TSRange = TSRange
return M
