return {
  {
    "nvim-neo-tree/neo-tree.nvim", -- 文件树插件本体
    dependencies = {
      "nvim-lua/plenary.nvim",        -- Lua 工具函数集
      "MunifTanjim/nui.nvim",         -- UI 组件库
      "nvim-tree/nvim-web-devicons",  -- 文件类型图标
    },
    cmd = "Neotree", -- 首次执行 :Neotree 命令时懒加载
    keys = {
      { "<leader>e", "<Cmd>Neotree toggle<CR>", desc = "切换文件管理器" }, -- 空格+e 开关文件树
    },
    opts = {
      close_if_last_window = true, -- 若 tree 是标签页里最后一个窗口，则一并关闭（true=关闭）
      enable_cursor_hijack = true, -- 光标落在文件名上，避免左侧出现突兀的光标块
      event_handlers = {
        {
          event = "neo_tree_window_after_open",
          handler = function(args)
            vim.api.nvim_win_call(args.winid, function()
              vim.opt_local.fillchars:append({ eob = " " }) -- 隐藏空白区的 ~
              vim.opt_local.colorcolumn = "" -- 文件树不显示代码列参考线
            end)
          end,
        },
      },
      popup_border_style = "",   -- 弹窗边框风格（"NC" 为圆角；Neovim v0.11+ 可设 "" 用全局 winborder）

      clipboard = {
        sync = "global", -- 剪贴板同步方式："none"（不同步）/ "global"（所有实例共享）/ "universal"（跨实例通用）
      },

      enable_git_status = true,  -- 启用 Git 状态显示
      enable_diagnostics = true, -- 启用 LSP 诊断信息（错误/警告图标）显示

      open_files_do_not_replace_types = { "terminal", "trouble", "qf" }, -- 打开文件时不要替换这些类型的窗口（终端/Trouble/quickfix）
      open_files_using_relative_paths = false, -- 打开文件时是否使用相对路径
      sort_case_insensitive = false,           -- 排序是否不区分大小写
      sort_function = nil,                     -- 自定义排序函数（下方注释提供了按类型和路径降序的例子）
      -- 各组件（列）的默认配置
      default_component_configs = {
        container = {
          enable_character_fade = true, -- 启用字符渐隐效果（文件名过长时尾部渐隐）
        },
        indent = {
          indent_size = 2,                -- 缩进大小
          padding = 1,                    -- 左侧额外的内边距
          with_markers = true,            -- 显示缩进参考线
          indent_marker = "│",            -- 缩进参考线字符
          last_indent_marker = "└",       -- 最后一级缩进参考线字符
          highlight = "NeoTreeIndentMarker", -- 缩进参考线高亮组
          with_expanders = true,          -- 始终显示目录展开/折叠箭头
          expander_collapsed = "",       -- 折叠状态图标
          expander_expanded = "",        -- 展开状态图标
          expander_highlight = "NeoTreeExpander", -- 展开/折叠图标高亮组
        },
        icon = {
          folder_closed = "", -- 关闭的文件夹图标
          folder_open = "",   -- 打开的文件夹图标
          folder_empty = "󰜌",  -- 空文件夹图标
          -- 图标提供者：安装了 nvim-web-devicons 就用它取文件图标
          provider = function(icon, node, state)
            -- 只给「文件」和「终端」节点取图标
            if node.type == "file" or node.type == "terminal" then
              local success, web_devicons = pcall(require, "nvim-web-devicons") -- 安全加载图标库
              local name = node.type == "terminal" and "terminal" or node.name -- 终端用固定名，文件用文件名
              if success then
                -- default = true：未知扩展名也返回默认实心小方块图标，而不是 nil
                local devicon, hl = web_devicons.get_icon(name, nil, { default = true })
                icon.text = devicon or icon.text          -- 覆盖图标字形
                icon.highlight = hl or icon.highlight     -- 覆盖图标高亮颜色
              end
            end
          end,
          default = "*",              -- 后备图标（用了 web-devicons 默认图标后这行基本用不到）
          highlight = "NeoTreeFileIcon", -- 文件图标高亮组
          use_filtered_colors = true, -- 被过滤的文件（隐藏/点文件）是否用不同高亮颜色
        },
        modified = {
          symbol = "",              -- 文件被修改后显示的标记
          highlight = "NeoTreeModified", -- 修改标记高亮组
        },
        name = {
          trailing_slash = false,      -- 文件夹名称后是否显示斜杠
          use_filtered_colors = true,  -- 被过滤的文件是否用不同颜色
          use_git_status_colors = true, -- 是否使用 Git 状态颜色
          highlight = "NeoTreeFileName", -- 文件名高亮组
        },
        diagnostics = { -- 诊断符号列（文件/目录右侧显示错误警告数量）
          symbols = {
            error = "󰅗", -- 错误：方框 ×（U+F0157）
            warn = "󰀧",  -- 警告：方框 !（U+F0027）
            info = "󰬐",  -- 信息：方框字母 I（U+F0B10）
            hint = "󰞋",  -- 提示：方框 ?（U+F078B）
          },
        },
        git_status = {
          symbols = {
            added = "󰐖",     -- 新增：方框加号（U+F0416）
            modified = "󰏬",  -- 修改：方框铅笔（U+F03EC）
            deleted = "󰍵",   -- 删除：方框减号（U+F0375）
            renamed = "󰜵",   -- 重命名：方框右箭头（U+F0735）
            untracked = "󰞋", -- 未跟踪：方框问号（U+F078B）
            ignored = "",    -- 被忽略：斜杠眼睛（U+F474，neo-tree 默认）
            unstaged = "󰀧",  -- 未暂存：方框感叹号（U+F0027）
            staged = "󰄲",    -- 已暂存：方框对勾（U+F0132）
            conflict = "",   -- 冲突：合并图标（U+E727，neo-tree 默认）
          },
        },
        file_size = {
          enabled = true,       -- 显示文件大小
          width = 12,           -- 列宽
          required_width = 64,  -- 显示此列所需的最小窗口宽度
        },
        type = {
          enabled = true,       -- 显示文件类型
          width = 10,           -- 列宽
          required_width = 122, -- 显示此列所需的最小窗口宽度
        },
        last_modified = {
          enabled = true,       -- 显示最后修改时间
          width = 20,           -- 列宽
          required_width = 88,  -- 显示此列所需的最小窗口宽度
        },
        created = {
          enabled = true,       -- 显示创建时间
          width = 20,           -- 列宽
          required_width = 110, -- 显示此列所需的最小窗口宽度
        },
        symlink_target = {
          enabled = false,      -- 不显示符号链接的目标路径
        },
      },

      commands = {}, -- 自定义全局命令列表

      -- 窗口配置
      window = {
        position = "left", -- 窗口位置（左侧）
        width = 32,        -- 给文件名和目录层级留出空间
        mapping_options = {
          noremap = true,  -- 禁止递归映射
          nowait = true,   -- 无需等待后续按键
        },
        mappings = {
          ["<C-s>"] = {
            "quick_jump", -- 快速跳转（通过字母提示跳转到文件）
            config = {
              on_jump = "open_or_toggle",                -- 跳转后自动打开/切换目标节点
              jump_labels = "jfkdlsahgnuvrbytmiceoxwpqz", -- 跳转提示字母
            },
          },
          ["<Tab>"] = "select",            -- 选择节点
          ["<C-;>"] = "clear_selection",   -- 清除选择
          ["<space>"] = {
            "toggle_node",                 -- 展开/折叠节点
            nowait = false,                -- 如果有以空格开头的按键组合，需禁用 nowait
          },
          ["<2-LeftMouse>"] = "open",      -- 双击打开
          ["<cr>"] = "open",               -- 回车打开
          ["<esc>"] = "cancel",            -- 关闭预览或浮动窗口
          ["P"] = {
            "toggle_preview",              -- 切换预览模式（在浮窗中显示文件内容）
            config = {
              use_float = true,            -- 使用浮窗
              use_snacks_image = true,     -- 使用 snacks 图片支持
              use_image_nvim = true,       -- 使用 image.nvim 图片支持
            },
          },
          ["l"] = "focus_preview",         -- 聚焦到预览窗口
          ["S"] = "open_split",            -- 水平分屏打开
          ["s"] = "open_vsplit",           -- 垂直分屏打开
          ["t"] = "open_tabnew",           -- 在新标签页打开
          ["w"] = "open_with_window_picker", -- 使用窗口选择器打开
          ["C"] = "close_node",            -- 关闭节点
          ["z"] = "close_all_nodes",       -- 关闭所有节点
          ["a"] = {
            "add",                         -- 新建文件
            config = {
              show_path = "none",          -- 显示路径方式："none" / "relative" / "absolute"
            },
          },
          ["A"] = "add_directory",         -- 新建目录
          ["d"] = "delete",                -- 删除
          ["r"] = "rename",                -- 重命名
          ["b"] = "rename_basename",       -- 仅重命名基名
          ["y"] = "copy_to_clipboard",     -- 复制到剪贴板
          ["x"] = "cut_to_clipboard",      -- 剪切到剪贴板
          ["p"] = "paste_from_clipboard",  -- 从剪贴板粘贴
          ["<C-r>"] = "clear_clipboard",   -- 清空剪贴板
          ["c"] = "copy",                  -- 复制（需输入目标路径）
          ["m"] = "move",                  -- 移动（需输入目标路径）
          ["q"] = "close_window",          -- 关闭窗口
          ["R"] = "refresh",               -- 刷新
          ["?"] = "show_help",             -- 显示帮助
          ["<"] = "prev_source",           -- 切换到上一个数据源
          [">"] = "next_source",           -- 切换到下一个数据源
          ["i"] = "show_file_details",     -- 显示文件详情（时间等）
        },
      },

      nesting_rules = {}, -- 文件嵌套规则

      -- 文件系统数据源
      filesystem = {
        filtered_items = {
          visible = false,                 -- 是否可见（true 时以不同样式显示，而非完全隐藏）
          hide_dotfiles = true,            -- 隐藏以 . 开头的点文件
          hide_gitignored = true,          -- 隐藏被 .gitignore 忽略的文件
          hide_ignored = true,             -- 隐藏被其他类似 gitignore 文件忽略的文件
          ignore_files = { ".neotreeignore", ".ignore" }, -- 其他类似 gitignore 的文件（按优先级降序）
          hide_hidden = true,              -- 仅对 Windows 有效：隐藏系统隐藏文件/目录
          hide_by_name = {},               -- 按名称隐藏（如 "node_modules"）
          hide_by_pattern = {},            -- 按 glob 模式隐藏（如 "*.meta"）
          always_show = {},                -- 即使满足隐藏条件也始终显示
          always_show_by_pattern = {},     -- 按模式始终显示（如 ".env*"）
          never_show = {},                 -- 即使 visible 为 true 也永远不显示
          never_show_by_pattern = {},      -- 按模式永远不显示
        },
        follow_current_file = {
          enabled = false,                 -- 是否自动跟随/聚焦当前活动缓冲区对应的文件
          leave_dirs_open = false,         -- false 表示自动关闭自动展开的目录
        },
        group_empty_dirs = false,          -- 是否将空文件夹合并折叠显示
        hijack_netrw_behavior = "open_default", -- 接管 netrw 行为（open_default=打开目录默认用 neo-tree）
        use_libuv_file_watcher = false,    -- 是否用 OS 级文件监视器自动检测文件变化并刷新
        window = {
          mappings = {
            ["<bs>"] = "navigate_up",       -- 返回上一级目录
            ["."] = "set_root",             -- 将当前目录设为根目录
            ["H"] = "toggle_hidden",        -- 切换显示/隐藏隐藏文件
            ["/"] = "fuzzy_finder",         -- 模糊查找文件
            ["D"] = "fuzzy_finder_directory", -- 模糊查找目录
            ["#"] = "fuzzy_sorter",         -- 用 fzy 算法模糊排序
            ["f"] = "filter_on_submit",     -- 提交时过滤
            ["<c-x>"] = "clear_filter",     -- 清除过滤器
            ["[g"] = "prev_git_modified",   -- 上一个 Git 修改的文件
            ["]g"] = "next_git_modified",   -- 下一个 Git 修改的文件
            ["o"] = {                       -- 排序菜单（按 o 后再按对应键）
              "show_help",
              nowait = false,
              config = { title = "排序方式", prefix_key = "o" },
            },
            ["oc"] = { "order_by_created", nowait = false },     -- 按创建时间排序
            ["od"] = { "order_by_diagnostics", nowait = false }, -- 按诊断信息排序
            ["og"] = { "order_by_git_status", nowait = false },  -- 按 Git 状态排序
            ["om"] = { "order_by_modified", nowait = false },    -- 按修改时间排序
            ["on"] = { "order_by_name", nowait = false },        -- 按名称排序
            ["os"] = { "order_by_size", nowait = false },        -- 按大小排序
            ["ot"] = { "order_by_type", nowait = false },        -- 按类型排序
          },
          fuzzy_finder_mappings = {
            ["<down>"] = "move_cursor_down",   -- 向下移动
            ["<C-n>"] = "move_cursor_down",    -- 向下移动
            ["<up>"] = "move_cursor_up",       -- 向上移动
            ["<C-p>"] = "move_cursor_up",      -- 向上移动
            ["<esc>"] = "close",               -- 关闭
            ["<S-CR>"] = "close_keep_filter",  -- 关闭并保留过滤条件
            ["<C-CR>"] = "close_clear_filter", -- 关闭并清除过滤条件
            ["<C-w>"] = { "<C-S-w>", raw = true }, -- 原始映射（不经过 neo-tree 处理）
            {
              n = { -- 普通模式下的映射
                ["j"] = "move_cursor_down",   -- 向下移动
                ["k"] = "move_cursor_up",     -- 向上移动
                ["<S-CR>"] = "close_keep_filter", -- 关闭并保留过滤条件
                ["<C-CR>"] = "close_clear_filter", -- 关闭并清除过滤条件
                ["<esc>"] = "close",          -- 关闭
              },
            },
          },
        },
        commands = {}, -- 文件系统数据源的额外命令
      },

      -- 缓冲区数据源（查看当前打开的 buffers）
      buffers = {
        follow_current_file = {
          enabled = true,               -- 自动跟随当前活动缓冲区
          leave_dirs_open = false,      -- 不保留自动展开的目录
        },
        group_empty_dirs = true,        -- 合并空目录
        show_unloaded = true,           -- 显示未加载的缓冲区
        window = {
          mappings = {
            ["d"] = "buffer_delete",    -- 删除当前缓冲区
            ["bd"] = "buffer_delete",   -- 删除当前缓冲区
            ["<bs>"] = "navigate_up",   -- 返回上一级
            ["."] = "set_root",         -- 设为根目录
            ["o"] = {                   -- 排序菜单
              "show_help",
              nowait = false,
              config = { title = "排序方式", prefix_key = "o" },
            },
            ["oc"] = { "order_by_created", nowait = false },     -- 按创建时间排序
            ["od"] = { "order_by_diagnostics", nowait = false }, -- 按诊断信息排序
            ["om"] = { "order_by_modified", nowait = false },    -- 按修改时间排序
            ["on"] = { "order_by_name", nowait = false },        -- 按名称排序
            ["os"] = { "order_by_size", nowait = false },        -- 按大小排序
            ["ot"] = { "order_by_type", nowait = false },        -- 按类型排序
          },
        },
      },

      -- Git 状态数据源
      git_status = {
        window = {
          position = "float", -- Git 状态窗口以浮动窗口显示
          mappings = {
            ["A"] = "git_add_all",           -- 添加所有文件到暂存区
            ["gu"] = "git_unstage_file",     -- 取消暂存文件
            ["gU"] = "git_undo_last_commit", -- 撤销最后一次提交
            ["ga"] = "git_add_file",         -- 添加当前文件到暂存区
            ["gt"] = "git_toggle_file_stage", -- 切换文件暂存状态
            ["gr"] = "git_revert_file",      -- 还原文件修改
            ["gc"] = "git_commit",           -- 提交
            ["gp"] = "git_push",             -- 推送
            ["gl"] = "git_pull",             -- 拉取
            ["gg"] = "git_commit_and_push",  -- 提交并推送
            ["o"] = {                        -- 排序菜单
              "show_help",
              nowait = false,
              config = { title = "排序方式", prefix_key = "o" },
            },
            ["oc"] = { "order_by_created", nowait = false },     -- 按创建时间排序
            ["od"] = { "order_by_diagnostics", nowait = false }, -- 按诊断信息排序
            ["om"] = { "order_by_modified", nowait = false },    -- 按修改时间排序
            ["on"] = { "order_by_name", nowait = false },        -- 按名称排序
            ["os"] = { "order_by_size", nowait = false },        -- 按大小排序
            ["ot"] = { "order_by_type", nowait = false },        -- 按类型排序
          },
        },
      },
    },
  },
}
