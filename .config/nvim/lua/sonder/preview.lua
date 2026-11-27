-- 纯前端预览：起本地静态服务器 + 自动开浏览器 + 保存后自动刷新
-- 用法：打开 index.html 按 <leader>po；改 CSS/JS 保存后浏览器自动刷新
-- 关闭：<leader>pc（关闭全部预览服务）；状态：<leader>ps
local function open_preview()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("当前缓冲区没有文件，无法预览", vim.log.levels.WARN)
    return
  end

  local dir = vim.fn.fnamemodify(file, ":p:h")
  -- 从文件所在目录向上找 index.html，找到的那层作为服务根目录；
  -- 这样在 src/style.css 里按快捷键也能正确服务项目根
  local root = vim.fs.root(dir, "index.html") or dir

  -- HTML 直接打开当前页；CSS/JS 打开服务根目录的首页（index.html）
  if vim.bo.filetype == "html" or vim.bo.filetype == "htm" then
    require("prelive").go(root, file)
  else
    require("prelive").go(root)
  end
end

return {
  {
    "hat0uma/prelive.nvim",
    -- 只有用到这些命令或快捷键时才加载，不影响启动速度
    cmd = { "PreLiveGo", "PreLiveStatus", "PreLiveClose", "PreLiveCloseAll", "PreLiveLog" },
    opts = { server = { host = "127.0.0.1", port = 0 } }, -- 使用本机空闲端口，多个项目可同时预览。
    keys = {
      {
        "<leader>po",
        open_preview,
        ft = { "html", "htm", "css", "javascript" },
        desc = "起服务器并打开浏览器",
      },
      {
        "<leader>ps",
        function()
          require("prelive").status()
        end,
        ft = { "html", "htm", "css", "javascript" },
        desc = "预览服务状态",
      },
      {
        "<leader>pc",
        function()
          require("prelive").close(nil)
        end,
        ft = { "html", "htm", "css", "javascript" },
        desc = "关闭预览服务",
      },
    },
  },
}
