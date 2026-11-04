function nv --wraps nvim --description '启动自建 Neovim 配置（NVIM_APPNAME=nv，独立于 NvChad）'
    NVIM_APPNAME=nv command nvim $argv
end
