-- 解析器和查询作为一套安装，避免复用旧版 nvim-treesitter 的不兼容产物。
local parsers = require("sonder.language_tools").parsers

return {
  {
    "nvim-treesitter/nvim-treesitter", name = "sonder-treesitter", branch = "main",
    lazy = false, -- 新版插件需要在文件类型事件之前加入运行路径。
    config = function()
      local ts = require("nvim-treesitter")
      local data = vim.fn.stdpath("data")
      ts.setup({ install_dir = vim.fs.joinpath(data, "sonder-parsers") })

      -- Windows 发行的 CLI 默认尝试 cl；普通终端安装了 MinGW 时，显式传入编译器路径。
      -- 已配置的 CC/CXX、Visual Studio 开发者终端和 Linux 都沿用各自的工具链。
      if vim.fn.has("win32") == 1 and not vim.env.CC and vim.fn.executable("cl") == 0
          and vim.fn.executable("gcc") == 1 then
        vim.env.CC = vim.fn.exepath("gcc")
        if not vim.env.CXX and vim.fn.executable("g++") == 1 then
          vim.env.CXX = vim.fn.exepath("g++")
        end
      end

      -- 初次安装用 :SonderParsers；无界面部署可用带 ! 的同步形式检查结果。
      -- 日常编辑不会因缺少编译器或网络而等待；:TSUpdate 更新已安装的解析器。
      vim.api.nvim_create_user_command("SonderParsers", function(args)
        for _, program in ipairs({ "tree-sitter", "tar", "curl" }) do
          if vim.fn.executable(program) ~= 1 then
            error("缺少 " .. program .. "；请按 README 安装依赖，首次运行先完成 :MasonToolsInstallSync")
          end
        end
        local job = ts.install(parsers, { max_jobs = 3, summary = true })
        if args.bang then
          assert(job:wait(600000), "解析器安装未完成，请用 :TSLog 查看具体原因")
        end
      end, { bang = true, desc = "安装本配置所需的语法解析器" })

      -- 显式关联多种 Vim 文件类型与解析器；.vue 内部由查询注入 TS、JS、CSS。
      vim.treesitter.language.register("json5", { "jsonc", "json5" })
      -- 折叠是窗口选项。文件重新显示时也要选择对应的规则，差异比较窗口保留自己的折叠。
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        group = vim.api.nvim_create_augroup("SonderFolds", { clear = true }),
        callback = function(ev)
          local bo = vim.bo[ev.buf]
          if ev.buf ~= vim.api.nvim_get_current_buf() or bo.buftype ~= "" or bo.filetype == ""
              or vim.wo.diff or vim.b[ev.buf].snacks_bigfile or bo.filetype == "bigfile" then return end
          local lang = vim.treesitter.language.get_lang(bo.filetype)
          local ok, query = pcall(vim.treesitter.query.get, lang or bo.filetype, "folds")
          -- 有语法规则时按函数、标签、标题等结构折叠；缺少解析器或规则时按缩进折叠。
          local wo = vim.wo[0][0]
          if ok and query then
            wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
            wo.foldmethod = "expr"
          else
            wo.foldmethod = "indent"
          end
        end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("SonderSyntax", { clear = true }),
        pattern = { "rust", "vue", "javascript", "javascriptreact", "typescript", "typescriptreact",
          "html", "css", "sh", "bash", "markdown", "json", "jsonc", "json5", "toml", "yaml",
          "lua", "python", "vim", "help", "query" },
        callback = function(ev)
          -- 首次安装前保留 Vim 自带的语法着色；Snacks 接管的大文件跳过解析。
          if not vim.b[ev.buf].snacks_bigfile then
            pcall(vim.treesitter.start, ev.buf)
          end
        end,
      })
    end,
  },
}
