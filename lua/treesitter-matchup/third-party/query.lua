local api = vim.api
local ts = require 'treesitter-matchup.compat'
local tsrange = require "treesitter-matchup.third-party.tsrange"
local caching = require "treesitter-matchup.third-party.caching"

local M = {}

local EMPTY_ITER = function() end

do
  local query_cache = caching.create_buffer_cache()

  local function update_cached_matches(bufnr, changed_tick, query_group)
    local parser_loaded, parser = pcall(vim.treesitter.get_parser, bufnr)
    if parser_loaded and parser then
      local parser_first_root = parser:trees()[1]:root()

      query_cache.set(query_group, bufnr, {
        tick = changed_tick,
        cache = M.collect_group_results(bufnr, query_group, parser_first_root, parser) or {},
      })
    end
  end

  function M.get_matches(bufnr, query_group)
    bufnr = bufnr or api.nvim_get_current_buf()
    local cached_local = query_cache.get(query_group, bufnr)
    if not cached_local or api.nvim_buf_get_changedtick(bufnr) > cached_local.tick then
      update_cached_matches(bufnr, api.nvim_buf_get_changedtick(bufnr), query_group)
    end

    local cache_result = query_cache.get(query_group, bufnr)

    return cache_result and cache_result.cache or {}
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
  ---@param lang string
  ---@param query_name string
  function M.get_query(lang, query_name)
    if cache[lang][query_name] == nil then
      cache[lang][query_name] = ts.get_query(lang, query_name)
    end

    return cache[lang][query_name]
  end

  --- Invalidates the query file cache.
  --- If lang and query_name is both present, will reload for only the lang and query_name.
  --- If only lang is present, will reload all query_names for that lang
  --- If none are present, will reload everything
  ---@param lang string
  ---@param query_name string
  function M.invalidate_query_cache(lang, query_name)
    if lang and query_name then
      cache[lang][query_name] = nil
    elseif lang and not query_name then
      for query_name0, _ in pairs(cache[lang]) do
        M.invalidate_query_cache(lang, query_name0)
      end
    elseif not lang and not query_name then
      for lang0, _ in pairs(cache) do
        for query_name0, _ in pairs(cache[lang0]) do
          M.invalidate_query_cache(lang0, query_name0)
        end
      end
    else
      error "Cannot have query_name by itself!"
    end
  end
end

--- This function is meant for an autocommand and not to be used. Only use if file is a query file.
---@param fname string
function M.invalidate_query_file(fname)
  local fnamemodify = vim.fn.fnamemodify
  M.invalidate_query_cache(fnamemodify(fname, ":p:h:t"), fnamemodify(fname, ":t:r"))
end

---@class QueryInfo
---@field root LanguageTree
---@field source integer
---@field start integer
---@field stop integer

---@param bufnr integer
---@param query_name string
---@param root TSNode the root node
---@param parser LanguageTree language tree (parser) the root originates from
---@return Query|nil, QueryInfo|nil
local function prepare_query(bufnr, query_name, root, parser)
  local range = { root:range() }
  local query = M.get_query(parser:lang(), query_name)
  if not query then
    return
  end

  return query,
    {
      root = root,
      source = bufnr,
      start = range[1],
      -- The end row is exclusive so we need to add 1 to it.
      stop = range[3] + 1,
    }
end

local function TSRange_from_table(buf, range)
  return tsrange.TSRange.from_table(buf, range)
end

---@param query Query
---@param bufnr integer
---@param start_row integer
---@param end_row integer
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

  local matches = query:iter_matches(qnode, bufnr, start_row, end_row, { all = false })

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
          local metadata_path = split(name .. ".metadata")
          insert_to_path(prepared_match, metadata_path, metadata[id])
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
            insert_to_path(
              prepared_match,
              split(path .. ".node"),
              tsrange.TSRange.from_nodes(bufnr, match[pred[3]], match[pred[4]])
            )
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

---Iterates matches from a query file.
---@param bufnr integer the buffer
---@param query_group string the query file to use
---@param root TSNode the root node
---@param parser LanguageTree language tree (parser) the root originates from
function M.iter_group_results(bufnr, query_group, root, parser)
  local query, params = prepare_query(bufnr, query_group, root, parser)
  if not query then
    return EMPTY_ITER
  end
  assert(params)

  return M.iter_prepared_matches(query, params.root, params.source, params.start, params.stop)
end

---@param bufnr integer the buffer
---@param query_group string the query file to use
---@param root TSNode the root node
---@param parser LanguageTree the root node lang, if known
function M.collect_group_results(bufnr, query_group, root, parser)
  local matches = {}

  for prepared_match in M.iter_group_results(bufnr, query_group, root, parser) do
    table.insert(matches, prepared_match)
  end

  return matches
end

return M
