-- 每行依次是 LSP 配置名、可执行程序和 Mason 包名；同一份清单驱动安装与启用。
-- rust-analyzer 随 rustup 工具链安装，和 Cargo、rustfmt 共享项目的工具链选择。
local M = {}
-- 同一份解析器清单供首次安装和健康检查使用；Vue 的嵌入区域依赖 JS、TS、CSS。
M.parsers = {
  "rust", "vue", "javascript", "typescript", "tsx", "html", "css", "bash",
  "markdown", "markdown_inline", "json", "json5", "toml", "yaml", "lua", "python",
}
local servers = {
  { "rust_analyzer", "rust-analyzer" },
  { "vtsls", "vtsls", "vtsls" }, -- JS、TS、JSX、TSX 和 Vue 中的类型分析
  { "vue_ls", "vue-language-server", "vue-language-server" }, -- Vue 模板和样式
  { "cssls", "vscode-css-language-server", "css-lsp" },
  { "html", "vscode-html-language-server", "html-lsp" },
  { "jsonls", "vscode-json-language-server", "json-lsp" }, -- 也支持带注释的 JSON
  { "yamlls", "yaml-language-server", "yaml-language-server" },
  { "taplo", "taplo", "taplo" }, -- 同时提供 TOML 格式化和 LSP
  { "marksman", "marksman", "marksman" }, -- Markdown 标题、链接和跨文件引用
  { "bashls", "bash-language-server", "bash-language-server" },
  { "lua_ls", "lua-language-server", "lua-language-server" }, -- 编辑 Neovim 自己的配置
}

-- Mason 负责提供各平台的入口文件；工具名无需拼接 .exe 或 .cmd。
function M.packages()
  -- ShellCheck 为 bashls 提供诊断，shfmt 专门负责 Shell 排版。
  local packages = { "prettier", "shfmt", "shellcheck", "stylua", "ruff", "tree-sitter-cli" }
  for _, server in ipairs(servers) do
    if server[3] then
      table.insert(packages, server[3])
    end
  end
  return packages
end

-- 合并启用新装好的服务。首次下载期间可以继续编辑，完成后在已打开的文件也生效。
local function enable_available()
  local available = {}
  for _, server in ipairs(servers) do
    if not vim.lsp.is_enabled(server[1]) and vim.fn.executable(server[2]) == 1 then
      table.insert(available, server[1])
    end
  end
  if #available > 0 then
    vim.lsp.enable(available)
  end
end

function M.setup_lsp()
  local group = vim.api.nvim_create_augroup("SonderLanguageTools", { clear = true })
  -- 告诉服务器补全菜单支持代码片段；HTML 标签、CSS 属性等补全依赖这项能力。
  vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

  -- Vue 官方的混合模式：vue_ls 将脚本请求转交给 vtsls。
  -- 路径指向语言服务包，TypeScript 从这里解析 @vue/typescript-plugin。
  local vue_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages",
    "vue-language-server", "node_modules", "@vue", "language-server")
  vim.lsp.config("vtsls", {
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
    settings = { vtsls = { tsserver = { globalPlugins = {
      { name = "@vue/typescript-plugin", location = vue_dir, languages = { "vue" }, configNamespace = "typescript" },
    } } } },
  })
  -- JSON 与 TOML 的常用项目文件按文件名关联规范，其他文件仍可声明自己的 schema。
  -- Taplo 0.10 无法解析 SchemaStore 新版目录格式，直接关联避免每次启动下载并解析整张目录。
  vim.lsp.config("jsonls", {
    settings = { json = { validate = { enable = true }, schemas = {
      { fileMatch = { "package.json" }, url = "https://www.schemastore.org/package.json" },
      { fileMatch = { "tsconfig.json", "tsconfig.*.json" }, url = "https://www.schemastore.org/tsconfig.json" },
    } } },
  })
  vim.lsp.config("taplo", {
    settings = { evenBetterToml = { schema = { catalogs = {}, associations = {
      [".*/Cargo\\.toml$"] = "https://www.schemastore.org/cargo.json",
      [".*/pyproject\\.toml$"] = "https://www.schemastore.org/pyproject.json",
    } } } },
  })
  -- BashLS 在 Windows 内部用 Node 启动 ShellCheck，要交给它原生 exe 而非 Mason 的 cmd 入口。
  if vim.fn.has("win32") == 1 then
    local checker = vim.fn.exepath("shellcheck.exe")
    if checker == "" then
      checker = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "shellcheck", "shellcheck.exe")
    end
    vim.lsp.config("bashls", { settings = { bashIde = { shellcheckPath = checker } } })
  end
  -- Neovim 配置自带 LuaJIT 和 vim 全局对象，普通 Lua 工程沿用其 .luarc.json。
  local lua_markers = vim.deepcopy(vim.lsp.config.lua_ls.root_markers)
  table.insert(lua_markers, #lua_markers, "lazy-lock.json") -- 独立部署的配置目录通常没有 .git。
  vim.lsp.config("lua_ls", {
    root_markers = lua_markers,
    on_init = function(client)
      local root = client.root_dir
      if not root or not vim.fs.relpath(vim.fn.stdpath("config"), root) then
        return
      end
      if vim.uv.fs_stat(vim.fs.joinpath(root, ".luarc.json")) or vim.uv.fs_stat(vim.fs.joinpath(root, ".luarc.jsonc")) then
        return
      end
      client.settings.Lua = vim.tbl_deep_extend("force", client.settings.Lua or {}, {
        runtime = { version = "LuaJIT" },
        workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
      })
    end,
  })

  -- 只在已有语言服务的缓冲区接管这些按键，文档缓冲区仍可使用原始 Vim 行为。
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(ev)
      local function map(key, action, description)
        vim.keymap.set("n", key, action, { buffer = ev.buf, desc = description })
      end
      map("gd", vim.lsp.buf.definition, "转到定义")
      map("gD", vim.lsp.buf.declaration, "转到声明")
      map("gr", vim.lsp.buf.references, "查找引用")
      map("gi", vim.lsp.buf.implementation, "转到实现")
      map("K", vim.lsp.buf.hover, "查看符号文档")
      map("<leader>rn", vim.lsp.buf.rename, "重命名符号")
      map("<leader>ca", vim.lsp.buf.code_action, "执行代码操作")
      map("<leader>df", vim.diagnostic.open_float, "查看当前诊断")
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group, pattern = "MasonToolsUpdateCompleted", callback = enable_available,
  })
  enable_available()
end

return M
