-- From https://github.com/nvim-treesitter/playground
-- Copyright 2021
-- licensed under the Apache License 2.0
-- See nvim-treesitter.LICENSE-APACHE-2.0

local api = vim.api
local ts = vim.treesitter
local highlighter = require "vim.treesitter.highlighter"

local M = {}

function M.debounce(fn, debounce_time)
  local timer = vim.loop.new_timer()
  local is_debounce_fn = type(debounce_time) == "function"

  return function(...)
    timer:stop()

    local time = debounce_time
    local args = { ... }

    if is_debounce_fn then
      time = debounce_time()
    end

    timer:start(
      time,
      0,
      vim.schedule_wrap(function()
        fn(unpack(args))
      end)
    )
  end
end

function M.get_hl_groups_at_position(bufnr, row, col)
  local buf_highlighter = highlighter.active[bufnr]

  if not buf_highlighter then
    return {}
  end

  local matches = {}

  buf_highlighter.tree:for_each_tree(function(tstree, tree)
    if not tstree then
      return
    end

    local root = tstree:root()
    local root_start_row, _, root_end_row, _ = root:range()

    -- Only worry about trees within the line range
    if root_start_row > row or root_end_row < row then
      return
    end

    local query = buf_highlighter:get_query(tree:lang())

    -- Some injected languages may not have highlight queries.
    if not query:query() then
      return
    end

    local iter = query:query():iter_captures(root, buf_highlighter.bufnr, row, row + 1)

    for capture, node, metadata in iter do
      local hl = query.hl_cache[capture]

      if hl and ts.is_in_node_range(node, row, col) then
        local c = query._query.captures[capture] -- name of the capture in the query
        if c ~= nil then
          table.insert(matches, { capture = c, priority = metadata.priority })
        end
      end
    end
  end, true)
  return matches
end

function M.for_each_buf_window(bufnr, fn)
  if not api.nvim_buf_is_loaded(bufnr) then
    return
  end

  for _, window in ipairs(vim.fn.win_findbuf(bufnr)) do
    fn(window)
  end
end

function M.to_lookup_table(list, key_mapper)
  local result = {}

  for i, v in ipairs(list) do
    local key = v

    if key_mapper then
      key = key_mapper(v, i)
    end

    result[key] = v
  end

  return result
end

function M.node_contains(node, range)
  local start_row, start_col, end_row, end_col = node:range()
  local start_fits = start_row < range[1] or (start_row == range[1] and start_col <= range[2])
  local end_fits = end_row > range[3] or (end_row == range[3] and end_col >= range[4])

  return start_fits and end_fits
end

function M.is_in_node_range(node, line, col)
  local start_line, start_col, end_line, end_col = ts.get_node_range(node)
  if line >= start_line and line <= end_line then
    if line == start_line and line == end_line then
      return col >= start_col and col < end_col
    elseif line == start_line then
      return col >= start_col
    elseif line == end_line then
      return col < end_col
    else
      return true
    end
  else
    return false
  end
end

--- Returns a tuple with the position of the last line and last column (0-indexed).
function M.get_end_pos(bufnr)
  local bufnr = bufnr or api.nvim_get_current_buf()
  local last_row = api.nvim_buf_line_count(bufnr) - 1
  local last_line = api.nvim_buf_get_lines(bufnr, last_row, last_row + 1, true)[1]
  local last_col = last_line and #last_line or 0
  return last_row, last_col
end

return M
