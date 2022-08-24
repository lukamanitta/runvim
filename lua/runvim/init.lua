local M = {}
local options = {}

function M.setup(opts)
    require("runvim.config").set_options(opts)
    options = require("runvim.config").options

    vim.api.nvim_create_user_command("TestCbQuery", function()
        require("runvim.markdown_codeblock").get_codeblock_under_cursor()
    end, {})
end

return M
