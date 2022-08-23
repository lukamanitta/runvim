local U = {}

local code_block = vim.treesitter.parse_query(
    "markdown",
    [[
(fenced_code_block
    (info_string
        (language) @language
    )
    (code_fence_content) @content
)
    ]]
)

local get_root = function(bufnr)
    local parser = vim.treesitter.get_parser(bufnr, "markdown", {})
    local tree = parser:parse()[1]
    return tree:root()
end

U.get_codeblock_under_cursor = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local root = get_root(bufnr)

    for pattern, match in code_block:iter_captures(root, bufnr, 0, -1) do
        local language
        local content
        for id, node in pairs(match) do
            local capture_name = code_block.captures[id]
            if capture_name == "language" then
                language = node:get_node_text(bufnr)
            elseif capture_name == "content" then
                content = node:get_node_text(bufnr)

                local start_row, _, end_row, _ = node:range()
                local linenr = vim.api.nvim_win_get_cursor(0)[1]
                if start_row <= linenr and linenr <= end_row then
                    vim.notify("Inside a code block of language " .. language)
                end
            end
        end
    end
end

return U
