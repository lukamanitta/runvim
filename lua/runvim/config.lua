local config = {}

-- Default config
config.options = {
    result_window_type = "notify", -- 'float', 'bot', 'top', 'left', 'right', 'notify'
    float_window_options = {
        relative = "editor",
        width = 80,
        height = 20,
        row = 1,
        col = 1,
        style = "minimal",
        border = "single",
        focusable = false,
    },
    rules = {
        python = function(filename)
            vim.cmd(":!python3 " .. filename)
        end,
        javascript = {
            command = "node",
            with_filename = true,
        },
        rust = {
            command = "cargo run",
            with_filename = false,
        },
    },
}

function config.set_options(opts)
    opts = opts or {}
    config.options = vim.tbl_deep_extend("keep", opts, config.options)
end

return config
