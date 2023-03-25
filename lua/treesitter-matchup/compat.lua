local M = {}

local ts = vim.treesitter
local tsq = vim.treesitter.query

M.get_node_text = function(node, source, opts)
    return (ts.get_node_text or tsq.get_node_text)(node, source, opts)
end

M.get_query = function(lang, query_name)
    return (tsq.get or tsq.get_query)(lang, query_name)
end

return M
