-- 诊断显示：符号列提示位置，光标所在行下方自动展开详细信息
-- 图标取自 icons.lua 里 B 组那一套，与 neotree / bufferline / lualine 保持一致
vim.diagnostic.config({
  virtual_text = false, -- 不把长错误信息挤在代码行尾
  virtual_lines = { current_line = true }, -- 移到有诊断的行时自动显示，移开后收起
  underline = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅗", -- 错误：方框 ×（U+F0157）
      [vim.diagnostic.severity.WARN] = "󰀧",  -- 警告：方框 !（U+F0027）
      [vim.diagnostic.severity.INFO] = "󰬐",  -- 信息：方框字母 I（U+F0B10）
      [vim.diagnostic.severity.HINT] = "󰞋",  -- 提示：方框 ?（U+F078B）
    },
  },
  severity_sort = true,      -- 诊断按严重程度排序，错误排在警告前面
  update_in_insert = false,  -- 插入模式下不实时刷新诊断，避免打字时闪烁
})
