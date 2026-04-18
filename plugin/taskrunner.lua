-- plugin/taskrunner.lua
-- Loaded automatically by Neovim.  Registers the :Task user command.

if vim.g.loaded_taskrunner then return end
vim.g.loaded_taskrunner = true

-- :Task <cmd> [args...]
-- Runs an arbitrary shell command through taskrunner with sensible defaults.
vim.api.nvim_create_user_command("Task", function(args)
    local parts = vim.split(args.args, "%s+", { trimempty = true })
    if #parts == 0 then
        vim.notify("Usage: :Task <cmd> [args...]", vim.log.levels.WARN, { title = "taskrunner" })
        return
    end
    require("taskrunner").run(parts, {
        title = args.args,
        id    = "taskrunner_cmd_" .. parts[1],
    })
end, {
    nargs = "+",
    desc  = "Run a shell command via taskrunner (async, quickfix on failure)",
    complete = "shellcmd",
})
