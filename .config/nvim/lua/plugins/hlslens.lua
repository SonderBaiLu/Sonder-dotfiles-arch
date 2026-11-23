return {
  {
    "kevinhwang91/hlslens", -- 搜索高亮计数（原作者的仓库地址，有永久重定向，比组织名更稳）
    enabled = false, -- ⚠️ 暂时禁用：此仓库还没过 GitHub「网页允许」白名单，克隆被拒。
    -- 放行后（浏览器打开 github.com/kevinhwang91/hlslens 通过审核），删掉本行再 :Lazy sync 即可启用
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
