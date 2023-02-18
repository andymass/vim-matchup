-- From https://github.com/nvim-treesitter/playground
-- Copyright 2021
-- licensed under the Apache License 2.0
-- See nvim-treesitter.LICENSE-APACHE-2.0

local ts = vim.treesitter
local utils = require "treesitter-matchup.third-party.utils"
local highlighter = require "vim.treesitter.highlighter"

local M = {}

if vim.treesitter.highlighter.hl_map and vim.fn.has('nvim-0.9.0') == 0 then
  function M.get_treesitter_hl(cursor)
    local buf = vim.api.nvim_get_current_buf()
    local row, col = unpack(cursor or vim.api.nvim_win_get_cursor(0))
    row = row - 1

    local self = highlighter.active[buf]

    if not self then
      return {}
    end

    local matches = {}

    self.tree:for_each_tree(function(tstree, tree)
      if not tstree then
        return
      end

      local root = tstree:root()
      local root_start_row, _, root_end_row, _ = root:range()

      -- Only worry about trees within the line range
      if root_start_row > row or root_end_row < row then
        return
      end

      local query = self:get_query(tree:lang())

      -- Some injected languages may not have highlight queries.
      if not query:query() then
        return
      end

      local iter = query:query():iter_captures(root, self.bufnr, row, row + 1)

      for capture, node, _ in iter do
        if ts.is_in_node_range(node, row, col) then
          local c = query._query.captures[capture] -- name of the capture in the query
          if c ~= nil then
            local general_hl, is_vim_hl = query:_get_hl_from_capture(capture)
            local local_hl = not is_vim_hl and (tree:lang() .. general_hl)
            local line = { c }
            if local_hl then
              table.insert(line, local_hl)
            end
            if general_hl and general_hl ~= local_hl then
              table.insert(line, general_hl)
            end
            table.insert(matches, line)
          end
        end
      end
    end, true)
    return matches
  end
else
  function M.get_treesitter_hl(cursor)
    local bufnr = vim.api.nvim_get_current_buf()
    local row, col = unpack(cursor or vim.api.nvim_win_get_cursor(0))
    row = row - 1

    local results = utils.get_hl_groups_at_position(bufnr, row, col)
    local highlights = {}
    for _, hl in pairs(results) do
      local line = { "@" .. hl.capture }
      if hl.priority then
        table.insert(line, hl.priority)
      end
      table.insert(highlights, line)
    end
    return highlights
  end
end

function M.active()
  local buf = vim.api.nvim_get_current_buf()
  if highlighter.active[buf] then
    return true
  end
  return false
end

return M
