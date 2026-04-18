# taskrunner.nvim

Have you of the `:make` command in vim/neovim? Well it is basically a command
that runs the compile command for your project and conviently puts any errors
in the quickfix list. The only problem with it is that the whole Neovim screen
freezes while its happening and you are forced to sit there are wait.

But not anymore! This plugin solves that problem and allows you to run the
compile command in the background and still get the errors in the quickfix
list! Now you can continue working while the project is building!

## Demo Video

https://github.com/user-attachments/assets/9f0c9f2f-9f06-4067-b9c8-b98e838cbf3b

## Requirements

- Neovim ≥ 0.10
- [snacks.nvim](https://github.com/folke/snacks.nvim) with the `notifier` component enabled

## Installation

### lazy.nvim

```lua
{
    "agokule/taskrunner.nvim",
    opts = {
        -- see Configuration below
    },
}
```

## Configuration

```lua
require("taskrunner").setup({
    -- errorformat applied before every run.
    -- nil = leave vim.o.errorformat untouched.
    -- Use the bundled gcc/cmake format:
    --   errorformat = require("taskrunner").GCC_CMAKE_EFM
    errorformat = nil,

    -- Open :copen automatically when a task fails.
    open_qf_on_failure = true,

    -- Stdout lines matching any of these patterns flip the spinner to ✓ (completed).
    success_patterns = {
        "Build files have been written to:",
        "Built target",
    },

    icons = {
        success = " ",
        failure = " ",
        spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
    },
})
```

## Usage

### Lua API

#### `run(cmd, opts)`

Run a single command asynchronously.

```lua
local tr = require("taskrunner")

tr.run({ "cmake", "--build", "build" }, {
    title      = "CMake Build",   -- shown in the notification header
    id         = "cmake_build",   -- deduplicates snacks notifications
    efm        = nil,             -- per-task errorformat (overrides config)
    on_success = function() vim.notify("Done!") end,
    on_failure = function(obj) print("exit code:", obj.code) end,
})
```

#### `chain(tasks, global_opts?)`

Run tasks sequentially; a failure stops the chain.

```lua
local tr = require("taskrunner")

tr.chain({
    { cmd = { "cmake", "-S", ".", "-B", "build", "-DCMAKE_BUILD_TYPE=Debug" },
      title = "CMake Configure", id = "cmake_configure" },
    { cmd = { "cmake", "--build", "build" },
      title = "CMake Build",     id = "cmake_build" },
}, {
    efm = require("taskrunner").GCC_CMAKE_EFM,
})
```

### User command

```
:Task cmake --build build
:Task make
:Task npm run test
```

### Migrating the example `.nvim.lua`

```lua
-- .nvim.lua (project-local)
local tr = require("taskrunner")

tr.setup({
    errorformat    = tr.GCC_CMAKE_EFM,
    open_qf_on_failure = true,
})

vim.lsp.enable("clangd")
vim.o.autochdir = false

local configure_base = { "cmake", "-S", ".", "-B", "build" }

local function cmake(build_type)
    local cfg = vim.list_extend(
        vim.list_slice(configure_base, 1),  -- copy
        { "-DCMAKE_BUILD_TYPE=" .. build_type }
    )
    tr.chain({
        { cmd = cfg,                            title = "CMake Configure", id = "cmake_configure" },
        { cmd = { "cmake", "--build", "build" }, title = "CMake Build",    id = "cmake_build"     },
    })
end

vim.keymap.set("n", "<leader>rb", function() cmake("Debug")   end)
vim.keymap.set("n", "<leader>rB", function() cmake("Release") end)
vim.keymap.set("n", "<leader>rp", function()
    vim.cmd("botright 20sp")
    vim.cmd.terminal("./build/Timepad")
end)
vim.keymap.set("n", "<leader>fm", function() vim.cmd.edit("./src/main.cpp")      end)
vim.keymap.set("n", "<leader>fa", function() vim.cmd.edit("./src/appstate.hpp")  end)
```

## API Reference

| Symbol | Type | Description |
|---|---|---|
| `setup(opts)` | function | Configure the plugin |
| `run(cmd, opts)` | function | Run one command |
| `chain(tasks, opts?)` | function | Run commands sequentially |
| `GCC_CMAKE_EFM` | string | Bundled gcc/clang/cmake errorformat |
