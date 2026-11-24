-- 严格 HTML 校验：html-validate 输出 JSON，经 nvim-lint 转成 nvim 诊断
-- 注意：标签自动闭合由 nvim-ts-autotag 负责，标签补全由 html LSP 负责，
-- 这个文件只做「严格语法校验」，三者互不替代
return {
  {
    "mfussenegger/nvim-lint",
    -- 在 BufReadPre 加载，才能赶在同一个文件触发 BufReadPost 之前注册好校验钩子
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      -- html-validate 不在 nvim-lint 内置 linter 列表里，这里自定义
      lint.linters["html-validate"] = {
        cmd = "html-validate", -- 用户级 npm 安装，在 fish 的 PATH 里
        stdin = false, -- 直接把文件名传给命令（nvim-lint 会自动追加）
        args = {
          "--formatter=json", -- JSON 输出，便于解析
          "--rule=doctype-style:off", -- 关掉风格规则：prettier 会输出小写 doctype
          "--rule=void-style:off", -- 关掉风格规则：prettier 会输出 <meta /> 自闭合
        },
        stream = "stdout", -- 结果输出到 stdout
        ignore_exitcode = true, -- 有错误时退出码为 1，属于正常情况
        parser = function(output)
          if output == "" then
            return {}
          end

          local ok, decoded = pcall(vim.json.decode, output)
          if not ok or type(decoded) ~= "table" then
            return {}
          end

          local diagnostics = {}
          for _, result in ipairs(decoded) do
            for _, msg in ipairs(result.messages or {}) do
              table.insert(diagnostics, {
                lnum = msg.line - 1, -- nvim-lint 诊断用 0 基行号
                end_lnum = msg.line - 1,
                col = msg.column - 1, -- 列号同样 0 基
                end_col = msg.column - 1 + (msg.size or 0),
                severity = msg.severity == 2 and vim.diagnostic.severity.ERROR
                  or vim.diagnostic.severity.WARN,
                message = msg.message,
                source = "html-validate",
                code = msg.ruleId,
              })
            end
          end
          return diagnostics
        end,
      }

      -- 只对 HTML 文件启用，不影响其他语言
      lint.linters_by_ft = {
        html = { "html-validate" },
        htm = { "html-validate" },
      }

      -- 打开和保存时自动校验（不监听 InsertLeave，避免写代码时频繁起进程）
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
}
