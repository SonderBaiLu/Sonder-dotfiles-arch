return {
  {
    "folke/noice.nvim", -- 统一命令行/消息/搜索的弹出 UI（解决「各界面风格不统一」）
    event = "VeryLazy", -- 启动后空闲时加载，不拖慢启动
    dependencies = {
      "MunifTanjim/nui.nvim", -- 弹窗组件库
      "rcarriga/nvim-notify", -- 通知渲染（noice 会接管）
    },
    opts = {
      lsp = {
        -- 签名帮助交给 blink.cmp 显示，这里关掉避免两个弹窗打架
        signature = { enabled = false },
        -- hover 文档也交给 blink（K 键已绑定 vim.lsp.buf.hover）
        hover = { enabled = false },
        -- 进度消息用 noice 的样式渲染
        progress = { enabled = true },
      },
      presets = {
        bottom_search = true, -- 搜索时命令行显示在底部（经典 vim 位置）
        command_palette = true, -- 命令模式（:）用居中命令面板
        long_message_to_split = true, -- 长消息自动拆到独立窗口，不遮挡代码
        lsp_doc_border = true, -- LSP 文档窗口加圆角边框
      },
      cmdline = { enabled = true }, -- : 命令行用 noice 渲染
      messages = { enabled = true }, -- 消息用 noice 渲染
      popupmenu = { enabled = false }, -- 补全菜单交给 blink.cmp，别让 noice 抢
    },
    keys = {
      { "<leader>nl", "<Cmd>Noice last<CR>", desc = "最后一条消息" }, -- 空格+n l 查看最后一条消息
      { "<leader>nh", "<Cmd>Noice history<CR>", desc = "消息历史" },  -- 空格+n h 查看消息历史
      { "<leader>nd", "<Cmd>Noice dismiss<CR>", desc = "关闭消息" },  -- 空格+n d 清掉所有消息
    },
  },
}
