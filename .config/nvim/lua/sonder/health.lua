-- :checkhealth sonder 可在新机器上检查这套配置的依赖，与 Neovim 自带健康面板共用入口。
local M = {}
function M.check()
  vim.health.start("Sonder · 编辑器")
  vim.health.info("配置目录 " .. vim.fn.stdpath("config"))
  vim.health.info("数据目录 " .. vim.fn.stdpath("data"))
  for _, exe in ipairs({ "git", "node", "npm", "rg", "curl", "tar", "rust-analyzer", "rustfmt", "tree-sitter" }) do
    local path = vim.fn.exepath(exe)
    if path ~= "" then vim.health.ok(exe .. " → " .. path)
    else vim.health.warn("未找到 " .. exe .. "，请参照 README 的依赖说明") end
  end

  vim.health.start("Mason · 语言工具")
  local registry = require("mason-registry")
  for _, name in ipairs(require("sonder.language_tools").packages()) do
    if registry.is_installed(name) then vim.health.ok(name)
    else vim.health.warn("待安装 " .. name .. "，可运行 :MasonToolsInstallSync") end
  end

  vim.health.start("Tree-sitter · 解析器和高亮查询")
  for _, lang in ipairs(require("sonder.language_tools").parsers) do
    local ok, query = pcall(vim.treesitter.query.get, lang, "highlights")
    if ok and query then vim.health.ok(lang)
    else vim.health.warn(lang .. " 的解析器或查询未就绪，可运行 :SonderParsers 和 :TSLog") end
  end

  require("sonder.ime").check()
end
return M
