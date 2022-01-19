-- From https://github.com/nvim-treesitter/nvim-treesitter
-- Copyright 2021
-- licensed under the Apache License 2.0
-- See nvim-treesitter.LICENSE-APACHE-2.0

local api = vim.api
local tsq = require "vim.treesitter.query"
local tsrange = require "nvim-treesitter.tsrange"
local parsers = require "nvim-treesitter.parsers"
local caching = require "nvim-treesitter.caching"

local M = {}

local EMPTY_ITER = function() end

do
  local query_cache = caching.create_buffer_cache()

  local function update_cached_matches(bufnr, changed_tick, query_group)
    query_cache.set(query_group, bufnr, {
      tick = changed_tick,
      cache = M.collect_group_results(bufnr, query_group) or {},
    })
  end

  function M.get_matches(bufnr, query_group)
    bufnr = bufnr or api.nvim_get_current_buf()
    local cached_local = query_cache.get(query_group, bufnr)
    if not cached_local or api.nvim_buf_get_changedtick(bufnr) > cached_local.tick then
      update_cached_matches(bufnr, api.nvim_buf_get_changedtick(bufnr), query_group)
    end

    return query_cache.get(query_group, bufnr).cache
  end
end

do
  local mt = {}
  mt.__index = function(tbl, key)
    if rawget(tbl, key) == nil then
      rawset(tbl, key, {})
    end
    return rawget(tbl, key)
  end

  -- cache will auto set the table for each lang if it is nil
  local cache = setmetatable({}, mt)

  --- Same as `vim.treesitter.query` except will return cached values
  function M.get_query(lang, query_name)
    if cache[lang][query_name] == nil then
      cache[lang][query_name] = tsq.get_query(lang, query_name)
    end

    return cache[lang][query_name]
  end

  --- Invalidates the query file cache.
  --- If lang and query_name is both present, will reload for only the lang and query_name.
  --- If only lang is present, will reload all query_names for that lang
  --- If none are present, will reload everything
  function M.invalidate_query_cache(lang, query_name)
    if lang and query_name then
      cache[lang][query_name] = nil
    elseif lang and not query_name then
      for query_name, _ in pairs(cache[lang]) do
        M.invalidate_query_cache(lang, query_name)
      end
    elseif not lang and not query_name then
      for lang, _ in pairs(cache) do
        for query_name, _ in pairs(cache[lang]) do
          M.invalidate_query_cache(lang, query_name)
        end
      end
    else
      error "Cannot have query_name by itself!"
    end
  end
end

--- This function is meant for an autocommand and not to be used. Only use if file is a query file.
function M.invalidate_query_file(fname)
  local fnamemodify = vim.fn.fnamemodify
  M.invalidate_query_cache(fnamemodify(fname, ":p:h:t"), fnamemodify(fname, ":t:r"))
end

local function get_byte_offset(buf, row, col)
  local lines = api.nvim_buf_get_lines(buf, row, row + 1, false)
  if #lines < 1 then
    return
  end
  return api.nvim_buf_get_offset(buf, row) + vim.fn.byteidx(lines[1], col)
end

local function TSRange_from_table(buf, range)
  return setmetatable(
    {
      start_pos = {range[1], range[2], get_byte_offset(buf, range[1], range[2])},
      end_pos = {range[3], range[4], get_byte_offset(buf, range[3], range[4])},
      buf = buf,
      [1] = range[1],
      [2] = range[2],
      [3] = range[3],
      [4] = range[4],
    },
    tsrange.TSRange)
end

function M.iter_prepared_matches(query, qnode, bufnr, start_row, end_row)
  -- A function that splits  a string on '.'
  local function split(string)
    local t = {}
    for str in string.gmatch(string, "([^.]+)") do
      table.insert(t, str)
    end

    return t
  end
  -- Given a path (i.e. a List(String)) this functions inserts value at path
  local function insert_to_path(object, path, value)
    local curr_obj = object

    for index = 1, (#path - 1) do
      if curr_obj[path[index]] == nil then
        curr_obj[path[index]] = {}
      end

      curr_obj = curr_obj[path[index]]
    end

    curr_obj[path[#path]] = value
  end

  local matches = query:iter_matches(qnode, bufnr, start_row, end_row)

  local function iterator()
    local pattern, match, metadata = matches()
    if pattern ~= nil then
      local prepared_match = {}

      -- Extract capture names from each match
      for id, node in pairs(match) do
        local name = query.captures[id] -- name of the capture in the query
        if name ~= nil then
          local path = split(name .. ".node")
          insert_to_path(prepared_match, path, node)
          insert_to_path(prepared_match, split(name .. '.metadata'), metadata)
        end
      end

      -- Add some predicates for testing
      local preds = query.info.patterns[pattern]
      if preds then
        for _, pred in pairs(preds) do
          -- functions
          if pred[1] == "set!" and type(pred[2]) == "string" then
            insert_to_path(prepared_match, split(pred[2]), pred[3])
          end
          if pred[1] == "make-range!" and #pred == 4 then
            assert(type(pred[2]) == "string")
            local path = pred[2]
            insert_to_path(prepared_match, split(path..'.node'),
              tsrange.TSRange.from_nodes(bufnr, match[pred[3]], match[pred[4]]))
          end
          if pred[1] == "offset!" then
            local path = type(pred[2]) == "string" and pred[2] or query.captures[pred[2]]

            local offset_node = match[pred[2]]
            local range = {offset_node:range()}
            local start_row_offset = pred[3] or 0
            local start_col_offset = pred[4] or 0
            local end_row_offset = pred[5] or 0
            local end_col_offset = pred[6] or 0

            range[1] = range[1] + start_row_offset
            range[2] = range[2] + start_col_offset
            range[3] = range[3] + end_row_offset
            range[4] = range[4] + end_col_offset

            insert_to_path(prepared_match, split(path..'.node'),
              TSRange_from_table(bufnr, range))
          end
        end
      end

      return prepared_match
    end
  end
  return iterator
end

-- Iterates matches from a query file.
-- @param bufnr the buffer
-- @param query_group the query file to use
-- @param root the root node
-- @param root the root node lang, if known
function M.iter_group_results(bufnr, query_group, root, root_lang)
  local buf_lang = parsers.get_buf_lang(bufnr)

  if not buf_lang then
    return EMPTY_ITER
  end

  local parser = parsers.get_parser(bufnr, buf_lang)
  if not parser then
    return EMPTY_ITER
  end

  if not root then
    local first_tree = parser:trees()[1]

    if first_tree then
      root = first_tree:root()
    end
  end

  if not root then
    return EMPTY_ITER
  end

  local range = { root:range() }

  if not root_lang then
    local lang_tree = parser:language_for_range(range)

    if lang_tree then
      root_lang = lang_tree:lang()
    end
  end

  if not root_lang then
    return EMPTY_ITER
  end

  local query = M.get_query(root_lang, query_group)
  if not query then
    return EMPTY_ITER
  end

  -- The end row is exclusive so we need to add 1 to it.
  return M.iter_prepared_matches(query, root, bufnr, range[1], range[3] + 1)
end

function M.collect_group_results(bufnr, query_group, root, lang)
  local matches = {}

  for prepared_match in M.iter_group_results(bufnr, query_group, root, lang) do
    table.insert(matches, prepared_match)
  end

  return matches
end

return M
