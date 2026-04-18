vim.o.autochdir = false

vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME
                }
            }
        },
    },
    root_dir = vim.fn.expand('%:p:h')
})

vim.lsp.enable('lua_ls')
