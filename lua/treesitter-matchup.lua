local M = {}

-- Follow nvim-treesitter lead and just avoid some annoying warnings for this directive
vim.treesitter.query.add_directive("make-range!", function() end, true)

function M.init()
  if vim.g.vim_matchup_skip_deprecated then
    return
  end

  local nvim_ts_available, treesitter = pcall(require, 'nvim-treesitter')
  if nvim_ts_available and treesitter and treesitter.define_modules then
    treesitter.define_modules {
      matchup = {
        module_path = 'treesitter-matchup.internal',
        is_supported = function()
          return true
        end
      }
    }
  end
end

return M
