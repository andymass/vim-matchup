local M = {}

---@class matchup.DelimConfig
---@field count_fail 0|1
---@field nomids 0|1
---@field noskips 0|1|2
---@field start_plaintext 0|1
---@field stopline integer

---@class matchup.HotfixConfig
---@field enabled 0|1

---@class matchup.MappingsConfig
---@field enabled 0|1

---@class matchup.OffscreenConfig
---@field method 'status'|'status_manual'|'popup'
---@field scrolloff 0|1
---@field fullwidth 0|1
--@field highlight string Vim exclusive option. Intentionally excluded from type
--@field syntax_hl 0|1 Vim exclusive option. Intentionally excluded from type
---@field border 1|string|string[]

---@class matchup.MatchparenConfig
---@field deferred 0|1
---@field deferred_fade_time integer
---@field deferred_hide_delay integer
---@field deferred_show_delay integer
---@field enabled 0|1
---@field end_sign string
---@field hi_background 0|1
---@field hi_surround_always 0|1
---@field insert_timeout integer
---@field nomode string
---@field offscreen matchup.OffscreenConfig
---@field pumvisible 0|1
---@field singleton 0|1
---@field stopline integer
---@field timeout integer

---@class matchup.MatchprefHtmlConfig
---@field nolists 0|1
---@field tagnameonly 0|1

---@class matchup.MatchprefConfig
---@field html matchup.MatchprefHtmlConfig

---@class matchup.MotionConfig
---@field cursor_end 0|1
---@field enabled 0|1
---@field override_Npercent integer

---@class matchup.MouseConfig
---@field enabled 0|1

---@class matchup.OverrideConfig
---@field vimtex 1|0

---@class matchup.SurroundConfig
---@field enabled 0|1

---@class matchup.TextObjConfig
---@field enabled 0|1
---@field linewise_operators string[]

---@class matchup.TransmuteConfig
---@field enabled 0|1

---@class matchup.TreesitterConfig
---@field enabled boolean
---@field disabled string[]
---@field include_match_words boolean
---@field disable_virtual_text boolean
---@field enable_quotes boolean
---@field stopline integer

---@class matchup.Config
---@field delim matchup.DelimConfig
---@field enabled 0|1
---@field hotfix matchup.HotfixConfig
---@field mappings matchup.MappingsConfig
---@field matchparen matchup.MatchparenConfig
---@field matchpref matchup.MatchprefConfig
---@field motion matchup.MotionConfig
---@field mouse matchup.MouseConfig
---@field override matchup.OverrideConfig
---@field surround matchup.SurroundConfig
---@field text_obj matchup.TextObjConfig
---@field transmute matchup.TransmuteConfig
---@field treesitter matchup.TreesitterConfig

---@param opts matchup.Config
---@param validate boolean
local function do_setup(opts, validate)
  for mod, elem in pairs(opts --[[@as table<string, unknown|table<string, unknown>>]]) do
    if type(elem) == 'table' then
      for key, val in pairs(elem) do
        local opt = 'matchup_'..mod..'_'..key
        if validate and vim.g[opt] == nil then
            error(('invalid option name %s.%s'):format(mod, key))
        end
        vim.g[opt] = val
      end
    else
      if validate and vim.g[mod] == nil then
        error(('invalid option name %s'):format(mod))
      end
      vim.g[mod] = elem
    end
  end
end

---@param opts matchup.Config|{sync: boolean}
function M.setup(opts)
  local sync = opts.sync
  if sync then
    vim.cmd[[runtime! plugin/matchup.vim]]
  end

  opts.sync = nil
  ---@cast opts matchup.Config
  do_setup(opts, sync)
end

return M
