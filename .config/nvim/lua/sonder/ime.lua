-- 中英文输入法随上下文切换：代码用英文，注释与写作文件用中文。
-- Windows 调用 im-select.exe 切换键盘布局；Linux 使用 fcitx5-remote（备选 ibus）。
-- 只在上下文变化时切换，手动用 Shift/Ctrl+Space 切走的输入法不会被反复抢回。
local M = {}

local is_win = vim.fn.has("win32") == 1
local group = vim.api.nvim_create_augroup("SonderIME", { clear = true })
local enabled = vim.env.SONDER_IME ~= "0"
local backend, missing

-- 插入会话里的上下文状态；只在换行或行首注释符变化时重新判断。
local state = { comment = false, prefix = false, lnum = 0 }

local writing_fts = { markdown = true, ["markdown.mdx"] = true, text = true }

-- commentstring 只给出一种注释；补充同文件类型里常用的其他注释符。
local extra_prefixes = {
  c = { "//" }, cpp = { "//" }, cuda = { "//" }, objc = { "//" }, objcpp = { "//" },
  javascript = { "/*" }, javascriptreact = { "/*" }, typescript = { "/*" }, typescriptreact = { "/*" },
  vue = { "//", "/*" }, scss = { "//" }, sass = { "//" }, less = { "//" },
}

-- 行首注释符：优先读取 commentstring，再合并补充表；注释符统一去掉尾部空格。
local function comment_prefixes()
  local prefixes = {}
  local prefix = (vim.bo.commentstring or ""):match("^(.-)%%s")
  if prefix then
    prefix = prefix:gsub("%s+$", "")
    if prefix ~= "" then prefixes[prefix] = true end
  end
  for _, extra in ipairs(extra_prefixes[vim.bo.filetype] or {}) do
    prefixes[extra] = true
  end
  return prefixes
end

local function line_is_comment(prefixes)
  local line = vim.api.nvim_get_current_line():gsub("^%s+", "")
  for prefix in pairs(prefixes) do
    if vim.startswith(line, prefix) then
      -- 避免把 Shell/Python 的 shebang 当成注释。
      if prefix == "#" and vim.startswith(line, "#!") then return false end
      return true
    end
  end
  return false
end

-- 光标位于多行注释、文档注释或注入语言（如 Vue 的 script）的注释里。
local function in_comment_node()
  if vim.b.snacks_bigfile then return false end
  local ok = pcall(function()
    local parser = vim.treesitter.get_parser(0)
    if parser then parser:parse() end
  end)
  if not ok then return false end
  local found, node = pcall(vim.treesitter.get_node, { ignore_injections = false })
  if not found then return false end
  while node do
    if node:type():find("comment", 1, true) then return true end
    node = node:parent()
  end
  return false
end

local function context()
  if writing_fts[vim.bo.filetype] then return true, "写作文件" end
  if in_comment_node() then return true, "注释节点" end
  if line_is_comment(comment_prefixes()) then return true, "注释行首" end
  return false, "代码"
end
M.context = context -- 供 :SonderIME 与 headless 检查使用。

local function switch(tag)
  -- 无界面会话（headless、脚本）没有可切换的窗口，直接跳过。
  if not enabled or not backend or #vim.api.nvim_list_uis() == 0 then return end
  backend.set(tag)
end

local function apply(comment)
  if comment == state.comment then return end
  state.comment = comment
  switch(comment and "zh" or "en")
end

-- 换行或行首注释符变化时才重新判断，普通打字不会反复调用切换命令。
local function refresh(force)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local prefix = line_is_comment(comment_prefixes())
  if not force and lnum == state.lnum and prefix == state.prefix then return end
  state.lnum, state.prefix = lnum, prefix
  local comment = context()
  if force then
    -- 进入插入模式时强制对齐上下文；用户可能在普通模式手动切过输入法。
    state.comment = comment
    switch(comment and "zh" or "en")
  else
    apply(comment)
  end
end

local function setup_windows()
  local tool_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "sonder-tools")
  local exe = vim.fn.exepath("im-select.exe")
  if exe == "" then
    local local_exe = vim.fs.joinpath(tool_dir, "im-select.exe")
    if vim.uv.fs_stat(local_exe) then exe = local_exe end
  end
  if exe == "" then
    missing = "未找到 im-select.exe；请放到 " .. tool_dir .. " 或加入 PATH"
    return nil
  end
  local en, zh = "1033", vim.env.SONDER_IME_ZH or "2052" -- 美式键盘 / 微软拼音
  return {
    name = "im-select.exe", en = en, zh = zh,
    set = function(tag)
      vim.system({ exe, tag == "zh" and zh or en }, { text = true }, function() end)
    end,
    get = function()
      local ok, result = pcall(function()
        return vim.system({ exe }, { text = true }):wait(1000)
      end)
      if ok and result and result.code == 0 then return vim.trim(result.stdout or "") end
    end,
  }
end

local function setup_linux()
  if vim.fn.executable("fcitx5-remote") == 1 then
    local zh = vim.env.SONDER_IME_ZH or "rime"
    return {
      name = "fcitx5-remote", en = "停用输入法（-c）", zh = zh,
      set = function(tag)
        -- 停用后按键直达终端；-s 选中并激活中文输入法。
        local args = tag == "zh" and { "fcitx5-remote", "-s", zh } or { "fcitx5-remote", "-c" }
        vim.system(args, { text = true }, function() end)
      end,
      get = function()
        local ok, result = pcall(function()
          return vim.system({ "fcitx5-remote", "-n" }, { text = true }):wait(1000)
        end)
        if ok and result and result.code == 0 then return vim.trim(result.stdout or "") end
      end,
    }
  end
  if vim.fn.executable("ibus") == 1 then
    local en = vim.env.SONDER_IME_EN or "xkb:us::eng"
    local zh = vim.env.SONDER_IME_ZH or "libpinyin"
    return {
      name = "ibus", en = en, zh = zh,
      set = function(tag)
        vim.system({ "ibus", "engine", tag == "zh" and zh or en }, { text = true }, function() end)
      end,
      get = function()
        local ok, result = pcall(function()
          return vim.system({ "ibus", "engine" }, { text = true }):wait(1000)
        end)
        if ok and result and result.code == 0 then return vim.trim(result.stdout or "") end
      end,
    }
  end
  missing = "未找到 fcitx5-remote 或 ibus；请先启用 fcitx5/ibus"
  return nil
end

local function status_text()
  local lines = { "中英文自动切换：" .. (enabled and "开启" or "关闭") }
  if not backend then
    lines[#lines + 1] = missing or "未找到可用的输入法切换工具"
    return table.concat(lines, "\n")
  end
  lines[#lines + 1] = string.format("后端：%s（英文 %s；中文 %s）", backend.name, backend.en, backend.zh)
  local comment, reason = context()
  lines[#lines + 1] = "当前上下文：" .. (comment and "中文 · " .. reason or "英文 · " .. reason)
  lines[#lines + 1] = "当前输入法：" .. (backend.get() or "读取失败")
  return table.concat(lines, "\n")
end

function M.setup()
  if vim.env.SONDER_IME == "0" then return end
  backend = is_win and setup_windows() or setup_linux()

  vim.api.nvim_create_user_command("SonderIME", function(args)
    local arg = vim.trim(args.args)
    if arg == "off" then
      enabled = false
      vim.notify("中英文自动切换已关闭")
    elseif arg == "on" then
      if not backend then
        vim.notify(missing or "未找到可用的输入法切换工具", vim.log.levels.WARN)
        return
      end
      enabled = true
      if vim.fn.mode():sub(1, 1) == "i" then refresh(true) else switch("en") end
      vim.notify("中英文自动切换已开启")
    elseif arg == "" then
      vim.notify(status_text(), vim.log.levels.INFO)
    else
      vim.notify("用法：:SonderIME [off|on]", vim.log.levels.ERROR)
    end
  end, { nargs = "?", desc = "查看或开关中英文自动切换" })

  if not backend then
    vim.notify_once("输入法自动切换未启用：" .. (missing or "缺少切换工具"), vim.log.levels.WARN)
    return
  end

  vim.api.nvim_create_autocmd("InsertEnter", { group = group, callback = function() refresh(true) end })
  vim.api.nvim_create_autocmd("TextChangedI", { group = group, callback = function() refresh(false) end })
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function()
      state = { comment = false, prefix = false, lnum = 0 }
      switch("en")
    end,
  })
  -- 启动、命令行执行结束都回到英文，保证普通模式按键不会被输入法吃掉。
  vim.api.nvim_create_autocmd({ "CmdlineLeave", "VimEnter" }, { group = group, callback = function() switch("en") end })
end

function M.check()
  vim.health.start("输入法 · 中英文自动切换")
  if vim.env.SONDER_IME == "0" then
    vim.health.warn("SONDER_IME=0，自动切换已关闭")
    return
  end
  if not enabled then
    vim.health.warn("已通过 :SonderIME off 临时关闭")
    return
  end
  if not backend then
    vim.health.warn(missing or "未找到可用的输入法切换工具")
    return
  end
  vim.health.ok("后端：" .. backend.name)
  vim.health.ok("英文 " .. backend.en .. "；中文 " .. backend.zh)
  local current = backend.get()
  if current then vim.health.ok("当前输入法 " .. current)
  else vim.health.warn("无法读取当前输入法") end
end

return M
