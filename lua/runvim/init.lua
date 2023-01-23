local M = {}
local options = {}
local notify_options = { title = "runvim" }

local function _output_command_to_buffer(command_to_run, bufnr)
    vim.fn.jobstart(command_to_run, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data, _)
            if data then
                vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, data)
            end
        end,
        on_stderr = function(_, data, _)
            if data then
                vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, data)
            end
        end,
        on_exit = function(_, exit_code, _)
            if exit_code ~= 0 then
                vim.notify(
                    "Error running command",
                    vim.log.levels.INFO,
                    notify_options
                )
            end
        end,
    })
end

local function _build_command(rule, filename)
    local command_to_run = rule.command
    if rule.with_filename then
        command_to_run = command_to_run .. " " .. filename
    end
    return command_to_run
end

function M.run_file(filename)
    local filetype = vim.filetype.match({ filename = filename })

    local filetype_rule = options.rules[filetype]
    if type(filetype_rule) == "table" then
        local command_to_run = _build_command(filetype_rule, filename)
        local results_bufnr = vim.api.nvim_create_buf(false, true)
        if options.result_window_type == "float" then
            vim.api.nvim_open_win(
                results_bufnr,
                true,
                options.float_window_options
            )
            _output_command_to_buffer(command_to_run, results_bufnr)
        elseif options.result_window_type == "notify" then
            local output = vim.fn.trim(vim.fn.system(command_to_run))
            vim.notify(output, vim.log.levels.INFO, notify_options)
        end
    elseif type(filetype_rule) == "function" then
        filetype_rule(filename)
    end
end

local function _run_codeblock(code)
    local language = code.language
    local content = code.content

    -- Create tmp file buffer with codeblock content & correct filetype
    local bufnr = vim.fn.bufnr()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, content)
    vim.api.nvim_buf_set_option(bufnr, "filetype", language)

    -- Get bufnr filename and run _run_file
    local filename = vim.api.nvim_buffer_get_name(bufnr)
    M.run_file(filename)
end

function M.run_codeblock_under_cursor()
    local code = require("runvim.markdown-helpers").get_codeblock_under_cursor()
    _run_codeblock(code)
end

function M.run_named_codeblocks(filename, cb_names)
    local codeblocks = {}
    local all_codeblock_language

    -- Open buffer from filename if not already open
    local bufnr = 0

    for _, cb_name in ipairs(cb_names) do
        local codeblock =
        require("runvim.markdown-helpers").get_codeblock_from_name(
            bufnr,
            cb_name
        )

        -- Ensure all codeblocks are of the same language
        if all_codeblock_language ~= nil then
            if codeblock.language ~= all_codeblock_language then
                vim.notify(
                    "The codeblocks provided are not all of the same language.",
                    vim.log.levels.ERROR,
                    notify_options
                )
                return
            end
        else
            all_codeblock_language = codeblock.language
        end

        table.insert(codeblocks, codeblock)
    end

    for _, codeblock in ipairs(codeblocks) do
        _run_codeblock(codeblock)
    end
end

function M.run()
    if vim.api.nvim_buf_get_option(0, "filetype") == "markdown" then
        M.run_codeblock_under_cursor()
    else
        local filename = vim.api.nvim_buf_get_name(0)
        M.run_file(filename)
    end
end

function M.setup(user_opts)
    require("runvim.config").set_options(user_opts)
    options = require("runvim.config").options

    vim.api.nvim_create_user_command("Run", function()
        M.run()
    end, {
        desc = "Run either the codeblock under cursor, or the current open file.",
    })
    vim.api.nvim_create_user_command("RunFile", function(opts)
        local filename = opts.fargs[1]
        M.run_file(filename)
    end, {
        desc = "Run a file given the filename.",
    })
    vim.api.nvim_create_user_command("RunCodeblock", function(opts)
        -- M.run_codeblock_under_cursor()
        if opts.fargs[1] ~= nil then
            local filename = vim.api.nvim_buf_get_name(0)
            local cb_names = opts.fargs
            M.run_named_codeblocks(filename, cb_names)
        else
            M.run_codeblock_under_cursor()
        end
    end, {
        nargs = "*",
        desc = "Run the codeblock under the cursor.",
    })
    vim.api.nvim_create_user_command("RunCodeblockInFile", function(cmd_opts)
        local filename = cmd_opts.fargs[1]
        local cb_names = { unpack(cmd_opts.fargs, 2, -1) }
        M.run_named_codeblocks(filename, cb_names)
    end, {
        nargs = "+",
        desc = "Run one or a list of named codeblocks from a given file consecutively.",
    })
end

return M
