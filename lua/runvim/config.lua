local config = {}

config.options = {
    commands = {},
}

function config.set_options(opts)
    opts = opts or {}
    config.options = vim.tbl_deep_extend("keep", opts, config.options)
end

return config
