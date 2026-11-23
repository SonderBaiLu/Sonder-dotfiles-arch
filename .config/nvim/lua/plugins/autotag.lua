return {
  {
    "windwp/nvim-ts-autotag", -- 标签自动闭合/同步重命名（HTML / Vue / JSX / Svelte 等）
    event = { "BufReadPre", "BufNewFile" }, -- 打开文件就加载，输入时立刻生效
    dependencies = { -- 依赖 treesitter 提供标签结构信息
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      opts = {
        enable_close = true, -- 输入 <div> 后自动补出 </div>
        enable_rename = true, -- 改开标签时自动同步改闭标签
        enable_close_on_slash = false, -- 输入 "</" 时不自动补全（避免抢输入）
      },
      per_filetype = { -- 按文件类型单独开关（留空表示全部按上面统一设置）
        -- ["html"] = { enable_close = false }, -- 示例：如果想让 html 不自动闭合，取消注释
      },
    },
  },
}
