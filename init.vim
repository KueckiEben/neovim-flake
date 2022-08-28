" place your custom init.vim here!
colorscheme doom-one

lua << EOF
require("headlines").setup({
    norg = {
        headline_highlights = {"Headline1", "Headline2", "Headline3", "Headline4", "Headline5", "Headline6"},
        codeblock_highlight = {"NeorgCodeBlock"},
    }
})
-- indendt-blankline config
vim.opt.termguicolors = true


EOF
