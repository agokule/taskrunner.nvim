local M = {}
local config = require("taskrunner.config")

-- Re-export so callers can do: efm = require("taskrunner").GCC_CMAKE_EFM
M.GCC_CMAKE_EFM = require("taskrunner.config").GCC_CMAKE_EFM

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function split_lines(str)
    if type(str) ~= "string" then return {} end
    str = str:gsub("\r\n", "\n"):gsub("\r", "\n")
    local lines = {}
    for line in str:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    return lines
end

local function extend(t1, t2)
    for i = 1, #t2 do
        table.insert(t1, t2[i])
    end
end

-- ── Quickfix ─────────────────────────────────────────────────────────────────

local function qf_clear()
    vim.fn.setqflist({}, "r")
end

local function qf_append(title, lines)
    vim.fn.setqflist({}, "a", { title = title, lines = lines })
end

local function qf_open()
    local cfg = config.get()
    if cfg.open_qf_on_failure then
        vim.cmd("botright copen")
    end
end

-- ── Notifications ─────────────────────────────────────────────────────────────

local function spinning_icon()
    local cfg = config.get()
    local sp = cfg.icons.spinner
    return sp[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #sp + 1]
end

local function is_success_line(msg)
    for _, pat in ipairs(config.get().success_patterns) do
        if msg:match(pat) then return true end
    end
    return false
end

local function notify_progress(id, title, msg)
    vim.notify(msg, vim.log.levels.INFO, {
        id = id,
        title = title,
        opts = function(notif)
            notif.icon = is_success_line(msg)
                and config.get().icons.success
                or spinning_icon()
        end,
    })
end

local function notify_done(id, title, ok)
    local cfg = config.get()
    local level = ok and vim.log.levels.INFO or vim.log.levels.ERROR
    local msg   = ok and (title .. " succeeded") or (title .. " failed")
    vim.notify(msg, level, {
        id    = id,
        title = title,
        opts  = function(notif)
            notif.icon = ok and cfg.icons.success or cfg.icons.failure
        end,
    })
end

-- ── Core runner ───────────────────────────────────────────────────────────────

--- Run a single command asynchronously.
---
---@param cmd      string[]  Command + args, e.g. { "cmake", "--build", "build" }
---@param opts     table
---@field title    string?   Human-readable name shown in notifications (default: cmd joined)
---@field id       string?   Notification ID for deduplication (default: title)
---@field efm      string?   Per-task errorformat string (overrides config default)
---@field on_success fun()?  Callback called on exit code 0
---@field on_failure fun(obj)?  Callback called on non-zero exit
function M.run(cmd, opts)
    opts = opts or {}

    local title = opts.title or table.concat(cmd, " ")
    local id    = opts.id    or title
    local efm   = opts.efm   or config.get().errorformat
    local output = {}

    if efm then vim.o.errorformat = efm end

    qf_clear()

    vim.system(cmd, {
        text = true,

        stdout = function(_, data)
            if not data then return end
            local lines = split_lines(data)
            extend(output, lines)
            vim.schedule(function()
                notify_progress(id, title, data)
            end)
        end,

        stderr = function(_, data)
            if not data then return end
            local lines = split_lines(data)
            extend(output, lines)
            -- stderr goes to the notifier as an error AND accumulates for qf
            vim.schedule(function()
                vim.notify(data, vim.log.levels.WARN, {
                    id    = id .. "_err",
                    title = title,
                })
            end)
        end,

    }, function(obj)
        vim.schedule(function()
            local ok = obj.code == 0
            notify_done(id, title, ok)

            if ok then
                if opts.on_success then opts.on_success() end
            else
                qf_append(title, output)
                qf_open()
                if opts.on_failure then opts.on_failure(obj) end
            end
        end)
    end)
end

--- Run a list of tasks sequentially; a failure stops the chain.
---
--- Each entry is a table accepted by `M.run()`, i.e.
---   { cmd = {...}, title = "...", id = "...", efm = "..." }
---
---@param tasks table[]
---@param opts  table?   Global overrides applied to every task (e.g. efm)
function M.chain(tasks, opts)
    opts = opts or {}
    if #tasks == 0 then return end

    local function run_next(i)
        if i > #tasks then return end
        local task = vim.tbl_extend("keep", tasks[i], opts)
        task.on_success = function()
            run_next(i + 1)
        end
        M.run(task.cmd, task)
    end

    run_next(1)
end

--- Configure the plugin.  Call once from your init.lua / lazy config.
---@param opts table See lua/taskrunner/config.lua for all keys.
function M.setup(opts)
    config.set(opts)
end

return M
