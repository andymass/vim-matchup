--- Returns the parser for a specific buffer and attaches it to the buffer
---
--- If needed, this will create the parser.
---
--- If no parser can be created no error will be thrown.
---
---@see vim.treesitter.get_parser
local get_parser = vim.treesitter.get_parser
if vim.version.lt(vim.version(), '0.11.0') then
  get_parser = function(bufnr, lang, opts)
    if opts and opts.error then
      return vim.treesitter.get_parser(bufnr, lang, opts)
    end

    local success, parser_or_error = pcall(vim.treesitter.get_parser, bufnr, lang, opts)
    if success then
      return parser_or_error, nil
    else
      return success, parser_or_error
    end
  end
end

return get_parser
