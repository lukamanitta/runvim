local M = {}

function M.setup(opts)
    require("runvim.config").set_options(opts)
end

vim.api.nvim_create_user_command("TestCbQuery", function()
    require("markdown_codeblock").get_codeblock_under_cursor()
end, {})

return M
