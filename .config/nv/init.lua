-- ============================================================
--  Sonder · 自建 Neovim 配置
--  用 `nv` 命令启动（NVIM_APPNAME=nv），与 NvChad 完全隔离
-- ============================================================

-- 引导 lazy.nvim（插件管理器）
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "无法克隆 lazy.nvim：\n" .. out, "ErrorMsg" },
    }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

-- 基础选项 & 核心键位（都不依赖插件，先加载）
require("options")
require("keymaps")
require("ui.diagnostics") -- 诊断图标（符号列）

-- 加载全部插件：lua/plugins/*.lua 每个文件一个/一组插件
require("lazy").setup({
  { import = "plugins" },
  { import = "ui" },
  { import = "lsp" },
}, {
  checker = { enabled = false },        -- 不自动检查更新，需要时 :Lazy check
  change_detection = { notify = false },
})
