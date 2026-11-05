return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = { -- 符号列改成细竖线（NvChad 同款）：行号旁不会出现一堵方块墙
        add = { text = "┃" },          -- 新增：细竖线（gitsigns 默认，U+2503）
        change = { text = "┃" },       -- 修改：细竖线
        delete = { text = "󰍵" },       -- 删除：方框减号（U+F0375，与 NvChad 一致）
        topdelete = { text = "‾" },    -- 从文件顶部删除：上划线（gitsigns 默认，U+203E）
        changedelete = { text = "󱕖" }, -- 修改且删除：方框波浪（U+F1556，与 NvChad 一致）
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end
        map("n", "]c", function() gs.next_hunk() end, "下一个 hunk")
        map("n", "[c", function() gs.prev_hunk() end, "上一个 hunk")
        map("n", "<leader>hs", function() gs.stage_hunk() end, "暂存 hunk")
        map("n", "<leader>hr", function() gs.reset_hunk() end, "撤销 hunk")
        map("n", "<leader>hp", function() gs.preview_hunk() end, "预览 hunk")
        map("n", "<leader>hb", function() gs.blame_line() end, "blame 当前行")
      end,
    },
  },
}
