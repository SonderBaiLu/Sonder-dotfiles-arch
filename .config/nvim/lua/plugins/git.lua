return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = { -- 符号列图标：用户亲自选的 B 组方形图标，勿改
        add = { text = "󰐖" },          -- 新增：方框加号（U+F0416）
        change = { text = "󰏬" },       -- 修改：方框铅笔（U+F03EC）
        delete = { text = "󰍵" },       -- 删除：方框减号（U+F0375）
        topdelete = { text = "󰜸" },    -- 从文件顶部删除：方框上箭头（U+F0738）
        changedelete = { text = "󰏬" }, -- 修改且删除：沿用方框铅笔
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
