return {
  {
    "nvimdev/hlslens", -- 搜索高亮计数：n/N 跳转时在行首显示「第几个/共几个」
    event = { "BufReadPost", "BufNewFile" }, -- 打开文件就生效
    config = function()
      require("hlslens").setup({
        override_lens = true, -- 接管默认搜索高亮，显示计数
      })
      local opts = { noremap = true, silent = true } -- 键位通用选项：不递归、不刷屏
      -- 把 n 改造成「跳转 + 居中 + 展开折叠 + 刷新计数」（接管 keymaps.lua 里原来的 n）
      vim.keymap.set("n", "n", function()
        vim.cmd("normal! " .. vim.v.count1 .. "nzzzv") -- 跳到第 count 个下一个匹配，居中并展开折叠
        require("hlslens").start()                      -- 刷新匹配计数
      end, opts)
      -- 把 N 改造成「跳转 + 居中 + 展开折叠 + 刷新计数」
      vim.keymap.set("n", "N", function()
        vim.cmd("normal! " .. vim.v.count1 .. "Nzzzv") -- 跳到第 count 个上一个匹配
        require("hlslens").start()                      -- 刷新匹配计数
      end, opts)
    end,
  },
}
