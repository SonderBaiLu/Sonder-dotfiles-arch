-- 沿用上游的严格 HTML 校验，在读取和保存文件后异步运行，避免每次离开插入模式都启动 Node。
-- 直接把参数交给 Node，文件名包含空格、中文或 & 时仍能原样送达。
local ns = vim.api.nvim_create_namespace("sonder.html-validate")
local join = vim.fs.joinpath

local function cli_for(dir)
  -- 项目自己的校验器和规则优先；其次查找 Neovim 专用工具目录中的安装。
  local relative = "node_modules/html-validate/package.json"
  local manifest = vim.fs.find(relative, { path = dir, upward = true, type = "file" })[1]
    or join(vim.fn.stdpath("data"), "sonder-tools", relative)
  if vim.fn.filereadable(manifest) == 0 then return end
  local ok, pkg = pcall(vim.json.decode, table.concat(vim.fn.readfile(manifest), "\n"))
  if ok and type(pkg) == "table" then
    local bin = type(pkg.bin) == "table" and pkg.bin["html-validate"] or pkg.bin
    if type(bin) == "string" then return join(vim.fs.dirname(manifest), bin) end
  end
end

local function lint(ev)
  local buf = ev.buf
  if not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].filetype ~= "html" or vim.bo[buf].modified
      or vim.b[buf].snacks_bigfile or vim.fn.executable("node") ~= 1 then return end
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" then return end
  local dir = vim.fs.dirname(file)
  local cli = cli_for(dir)
  if not cli then return end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  vim.system({ "node", cli, "--formatter=json", file }, { cwd = dir, text = true }, vim.schedule_wrap(function(result)
    -- 用户可能已修改或关闭文件；丢弃旧版本的诊断，等待下一次保存。
    if not vim.api.nvim_buf_is_loaded(buf) or vim.api.nvim_buf_get_changedtick(buf) ~= tick then return end
    if result.code > 1 then
      vim.notify_once("HTML 校验器未能完成：" .. vim.trim(result.stderr or ""), vim.log.levels.WARN)
      return
    end
    local ok, reports = pcall(vim.json.decode, result.stdout or "")
    if not ok or type(reports) ~= "table" then return end
    local diagnostics = {}
    for _, report in ipairs(reports) do
      for _, msg in ipairs(report.messages or {}) do
        local row = math.max((msg.line or 1) - 1, 0)
        local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
        -- JS 以 UTF-16 计列，Neovim 诊断以字节计列，含中文和 emoji 的标签也能正确定位。
        local col = vim.str_byteindex(line, "utf-16", math.max((msg.column or 1) - 1, 0), false)
        table.insert(diagnostics, { lnum = row, col = col, message = msg.message,
          source = "html-validate", code = msg.ruleId,
          severity = msg.severity == 2 and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN })
      end
    end
    vim.diagnostic.set(ns, buf, diagnostics)
  end))
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  -- 读取结束后 Neovim 会再递增一次 changedtick，等本次事件结束再记录文件版本。
  group = vim.api.nvim_create_augroup("SonderHtml", { clear = true }), callback = vim.schedule_wrap(lint),
})
