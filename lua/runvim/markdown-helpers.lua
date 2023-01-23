local U = {}
local ts = vim.treesitter
local tsquery = vim.treesitter.query

local get_root = function(bufnr)
    local parser = vim.treesitter.get_parser(bufnr, "markdown", {})
    local tree = parser:parse()[1]
    return tree:root()
end

tsquery.add_predicate("under-cursor?", function(match, _, _, pred)
    local node = match[pred[2]]
    local start_row, _, end_row, _ = node:range()
    local linenr = vim.api.nvim_win_get_cursor(0)[1]
    return start_row <= linenr and linenr <= end_row
end)

function U.get_codeblock_under_cursor()
    local code_block = ts.parse_query(
        "markdown",
        [[
((fenced_code_block
    (info_string
        (language) @language
    )
    (code_fence_content) @content
) @codeblock (#under-cursor? @codeblock))
    ]]
    )

    local bufnr = vim.api.nvim_get_current_buf()
    local root = get_root(bufnr)

    local code = {}
    for pattern, match, metadata in code_block:iter_matches(root, bufnr, 0, -1) do
        for id, node in pairs(match) do
            local capture_name = code_block.captures[id]
            if capture_name == "language" then
                code.language = tsquery.get_node_text(node, bufnr)
            elseif capture_name == "content" then
                code.content =
                { tsquery.get_node_text(node, bufnr, { concat = true }) }
            end
        end
    end
    return code
end

function U.get_codeblock_from_name(bufnr, cb_name)
    local named_code_block = ts.parse_query("markdown", [[
(fenced_code_block
    ((info_string
        (language) @language
    ) @info_string (#lua-match? @info_string ".*{]] .. cb_name .. [[}"))
    (code_fence_content) @content
)
    ]])

    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local root = get_root(bufnr)
    local code = {}
    for pattern, match, metadata in named_code_block:iter_matches(root, bufnr, 0, -1) do
        for id, node in pairs(match) do
            local capture_name = named_code_block.captures[id]
            if capture_name == "language" then
                code.language = tsquery.get_node_text(node, bufnr)
            elseif capture_name == "content" then
                code.content =
                { tsquery.get_node_text(node, bufnr, { concat = true }) }
            end
        end
    end
    return code
end

return U
