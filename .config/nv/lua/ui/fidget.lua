return {
  {
    "j-hui/fidget.nvim", -- LSP 进度提示：右下角小窗显示「正在索引…」，风格统一
    event = "LspAttach", -- 有 LSP 挂上时才加载
    opts = {
      notification = {
        window = {
          winblend = 0, -- 不透明，避免跟其他浮窗风格不一致
        },
      },
      progress = {
        suppress_on_insert = true, -- 插入模式下不弹提示，不打断输入
      },
    },
  },
}
