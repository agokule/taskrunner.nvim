local M = {}

-- Patterns that flip the spinner to a ✓ icon mid-stream
local DEFAULT_SUCCESS_PATTERNS = {
    "Build files have been written to:",
    "Built target",
    "Install the project",
}

-- gcc / clang / cmake errorformat  (same as the original .nvim.lua)
local GCC_CMAKE_EFM = table.concat({
    -- Noise filters
    "%-G[%\\s%#%\\d%\\+%%]%[ ]%#Built target %m",
    "%-G[%\\s%#%\\d%\\+%%]%[ ]%#Building %m",
    "%-Gmake%[%^:]%#:%m",
    "%-G%[ ]%#%\\d%# | %m",
    "%-G%[ ]%#| %m",
    -- Primary error/warning patterns
    "%f:%l:%c: %t%*[^:]: %m",
    "%f:%l:%c: %m",
    "%f:%l: %t%*[^:]: %m",
    -- "In function" noise
    "%-G%f:%l: In function %m:",
    "%-G%f: In function %m:",
    "%-G%\\s%#",
    -- Exhaustive fallbacks
    "%*[^\"]\"%f\"%*\\D%l: %m",
    "\"%f\"%*\\D%l: %m",
    "%-Gg%\\?make[%*\\d]: *** [%f:%l:%m",
    "%-Gg%\\?make: *** [%f:%l:%m",
    "%-G%f:%l: (Each undeclared identifier is reported only once,",
    "%-G%f:%l: for each function it appears in.)",
    "%-GIn file included from %f:%l:%c:",
    "%-GIn file included from %f:%l:%c\\,",
    "%-GIn file included from %f:%l:%c",
    "%-GIn file included from %f:%l",
    "%-G%*[ ]from %f:%l:%c",
    "%-G%*[ ]from %f:%l:",
    "%-G%*[ ]from %f:%l\\,",
    "%-G%*[ ]from %f:%l",
    "%f:%l:%c:%m",
    "%f(%l):%m",
    "%f:%l:%m",
    "\"%f\"\\, line %l%*\\D%c%*[^ ] %m",
    -- Directory tracking
    "%D%*\\a[%*\\d]: Entering directory %*[`']%f'",
    "%X%*\\a[%*\\d]: Leaving directory %*[`']%f'",
    "%D%*\\a: Entering directory %*[`']%f'",
    "%X%*\\a: Leaving directory %*[`']%f'",
    "%DMaking %*\\a in %f",
    "%f|%l| %m",
}, ",")

M.GCC_CMAKE_EFM = GCC_CMAKE_EFM

local defaults = {
    --- Applied to vim.o.errorformat before every run (unless overridden per-task).
    --- Set to nil to leave errorformat untouched.
    --- Use `require("taskrunner").GCC_CMAKE_EFM` for the bundled gcc/cmake format.
    errorformat = nil,

    --- Open the quickfix window automatically on failure.
    open_qf_on_failure = true,

    --- Patterns matched against stdout lines.
    --- When a line matches, the spinner is replaced with the success icon.
    success_patterns = DEFAULT_SUCCESS_PATTERNS,

    icons = {
        success = " ",
        failure = " ",
        spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
    },
}

local current = vim.deepcopy(defaults)

function M.get()
    return current
end

function M.set(opts)
    current = vim.tbl_deep_extend("force", current, opts or {})
end

return M
