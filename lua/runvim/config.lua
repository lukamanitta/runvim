local config = {}

-- Default config
config.options = {
    commands = {
        python = function(filename)
            vim.cmd(":!python3 " .. filename)
        end,
        javascript = "node",
    },
}

function config.set_options(opts)
    opts = opts or {}
    config.options = vim.tbl_deep_extend("keep", opts, config.options)
end

return config
