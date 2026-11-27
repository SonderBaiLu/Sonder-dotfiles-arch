-- 入口只负责加载顺序；所有读写目录交给 stdpath，兼容 Windows、Linux 与自定义 XDG 目录。
if vim.fn.has("nvim-0.12") == 0 then
  vim.api.nvim_echo({ { "本配置需要 Neovim 0.12 或更高版本。请先用 nvim --version 检查版本。", "ErrorMsg" } }, true, {})
  return
end

-- 先加载基础编辑功能，首次下载插件期间也可使用，且 lazy 能正确识别空格前缀。
require("sonder.options")
require("sonder.keymaps")
require("sonder.html")
require("sonder.ime").setup() -- 中英文输入法按上下文自动切换

local lazypath = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "lazy.nvim")
if not vim.uv.fs_stat(vim.fs.joinpath(lazypath, "lua", "lazy", "init.lua")) then
  if vim.fn.executable("git") ~= 1 then
    vim.notify("首次安装插件需要 Git。安装后重启 Neovim。", vim.log.levels.ERROR)
    return
  end
  -- 锁文件也记录管理器版本；自行移走锁文件时才使用上游的 stable 标签。
  local revision = "stable"
  local lock_path = vim.fs.joinpath(vim.fn.stdpath("config"), "lazy-lock.json")
  if vim.fn.filereadable(lock_path) == 1 then
    local ok, lock = pcall(vim.json.decode, table.concat(vim.fn.readfile(lock_path), "\n"))
    if not ok or type(lock) ~= "table" then
      vim.notify("lazy-lock.json 无法读取。请从配置包恢复该文件，再重启 Neovim。", vim.log.levels.ERROR)
      return
    end
    if lock["lazy.nvim"] then revision = lock["lazy.nvim"].commit end
  end
  -- 在临时目录克隆成功后再就位，网络中断可直接重试，也允许两个窗口同时首次启动。
  local staging = lazypath .. ".install-" .. vim.fn.getpid()
  vim.fn.mkdir(vim.fs.dirname(lazypath), "p")
  local clone = vim.system({
    -- 从远端默认分支取得分支信息，随后只检出锁定版本的文件。浅镜像也能正常写回锁文件。
    "git", "clone", "--filter=blob:none", "--no-checkout",
    "https://github.com/folke/lazy.nvim.git", staging,
  }, { text = true }):wait()
  if clone.code == 0 then
    clone = vim.system({ "git", "-C", staging, "checkout", "--detach", revision }, { text = true }):wait()
  end
  local installed, err
  if clone.code == 0 then installed, err = vim.uv.fs_rename(staging, lazypath) end
  if not installed then
    vim.fn.delete(staging, "rf")
    if not vim.uv.fs_stat(vim.fs.joinpath(lazypath, "lua", "lazy", "init.lua")) then
      vim.notify("插件管理器安装失败：" .. (err or clone.stderr or ""), vim.log.levels.ERROR)
      return
    end
  end
end
vim.opt.rtp:prepend(lazypath)

-- 按职责装配，各个模块也负责声明自己的按键与中文说明。
local specs = {}
for _, module in ipairs({ "languages", "syntax", "editing", "preview", "ui" }) do
  vim.list_extend(specs, require("sonder." .. module))
end
require("lazy").setup(specs, {
  concurrency = 3, -- 首次安装最多同时处理三个插件，给语言服务和小内存机器留出余量。
  -- Neovim 会把模块绝对路径编码为缓存文件名。Windows 深目录容易超长，直接加载 Lua 更可靠。
  performance = { cache = { enabled = vim.fn.has("win32") == 0 } },
  checker = { enabled = false }, -- 升级由用户发起，避免后台更新改变工具行为。
  change_detection = { notify = false },
  rocks = { enabled = false }, -- 当前插件均不使用 LuaRocks，可省去另一套平台依赖。
})
