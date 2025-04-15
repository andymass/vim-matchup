-- From https://github.com/nvim-treesitter/nvim-treesitter
-- Copyright 2021
-- licensed under the Apache License 2.0
-- See nvim-treesitter.LICENSE-APACHE-2.0

local M = {}
local api = vim.api

---@param a any
---@return fun():any func a function returning the given value
local constant = function(a)
  return function()
    return a
  end
end

---@param a any
---@return fun(...):any func a function that returns the given value if it is a function,
---                     or a function that returns the given value.
local to_func = function(a)
  return type(a) == "function" and a or constant(a)
end

---@param a any
---@return any a passed argument value
local identity = function(a)
  return a
end

-- Memoizes a function based on the buffer tick of the provided bufnr.
-- The cache entry is cleared when the buffer is detached to avoid memory leaks.
-- The options argument is a table with two optional values:
--  - bufnr: extracts a bufnr from the given arguments.
--  - key: extracts the cache key from the given arguments.
---@param fn function the fn to memoize, taking the buffer as first argument
---@param options? {bufnr: integer?, key: string|fun(...): string?} the memoization options
---@return function: a memoized function
function M.memoize_by_buf_tick(fn, options)
  options = options or {}

  ---@type table<string, {result: any, last_tick: integer}>
  local cache = setmetatable({}, { __mode = "kv" })
  local bufnr_fn = to_func(options.bufnr or identity)
  local key_fn = to_func(options.key or identity)

  return function(...)
    local bufnr = bufnr_fn(...)
    local key = key_fn(...)
    local tick = api.nvim_buf_get_changedtick(bufnr)

    if cache[key] then
      if cache[key].last_tick == tick then
        return cache[key].result
      end
    else
      local function detach_handler()
        cache[key] = nil
      end

      -- Clean up logic only!
      api.nvim_buf_attach(bufnr, false, {
        on_detach = detach_handler,
        on_reload = detach_handler,
      })
    end

    cache[key] = {
      result = fn(...),
      last_tick = tick,
    }

    return cache[key].result
  end
end

return M
