if not pcall(require, 'nvim-treesitter') then
  return {init = function() end}
end

local treesitter = require 'nvim-treesitter'
local queries = require 'nvim-treesitter.query'

local M = {}

function M.init()
  treesitter.define_modules {
    matchup = {
      module_path = 'treesitter-matchup.internal',
      is_supported = function(lang)
        return queries.has_query_files(lang, 'matchup')
      end
    }
  }
end

return M
