local M = {}

local function do_setup(opts, validate)
  for mod, elem in pairs(opts) do
    for key, val in pairs(type(elem) == 'table' and elem or {}) do
      local opt = 'matchup_'..mod..'_'..key
      if validate and vim.g[opt] == nil then
          error(string.format('invalid option name %s.%s', mod, key))
      end
      vim.g[opt] = val
    end
  end
end

function M.setup(opts)
  local sync = opts.sync
  if sync then
    vim.cmd[[runtime! plugin/matchup.vim]]
  end

  do_setup(opts, sync)
end

return M
