-- TODO: remove module structure

local M = {}

function M.init()
  treesitter.define_modules {
    matchup = {
      module_path = 'treesitter-matchup.internal',
      is_supported = function(lang)
        return vim.treesitter.query.get(lang, 'matchup') ~= nil
      end
    }
  }
end

return M
