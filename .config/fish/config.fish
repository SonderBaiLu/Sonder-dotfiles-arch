# ==========================================
# Fish Shell 配置（精简版）
# ==========================================

# --- 编辑器 ---
set -gx EDITOR nvim
set -gx VISUAL nvim
# --- PATH ---
fish_add_path -p $HOME/.local/bin
fish_add_path -p $HOME/.cargo/bin
fish_add_path -p $HOME/.npm-global/bin

set -x PNPM_HOME $HOME/.local/share/pnpm
fish_add_path -p $PNPM_HOME

# pnpm（下面这组是正式写法：判重后加入 PATH；上方第 13-14 行与其重复，属遗留）
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- $PNPM_HOME/bin $PATH
    fish_add_path $PNPM_HOME/bin
end

# --- 现代命令替代 ---
if type -q eza
    alias ls 'eza --icons --git'
    alias ll 'eza -l --icons --git -a --group-directories-first'
    alias lt 'eza --tree --level=2 --icons'
end

if type -q bat
    alias cat bat
end
if type -q fd
    alias find fd
end

alias cp 'cp -i' mv 'mv -i' rm trash # trash-cli 防误删
alias df 'df -h' du 'du -h -d 1' free 'free -h'

# --- 工具初始化（仅在已安装时加载，启动更快）---
if type -q starship
    starship init fish | source
end
if type -q zoxide
    zoxide init fish --cmd cd | source
end

# --- 实用函数 ---
function mkcd
    mkdir -p $argv; and cd $argv
end

function extract
    if not test -f $argv[1]
        echo "❌ 文件不存在: $argv[1]"
        return 1
    end
    switch $argv[1]
        case *.tar.gz *.tgz
            tar xzf $argv[1]
        case *.tar.bz2
            tar xjf $argv[1]
        case *.tar.xz *.txz
            tar xJf $argv[1]
        case *.zip
            unzip $argv[1]
        case *.rar
            unrar x $argv[1]
        case *.7z
            7z x $argv[1]
        case '*'
            echo "❌ 未知格式: $argv[1]"
            return 1
    end
end

# Arch 一键更新
function update
    echo "🔄 更新系统..."
    sudo pacman -Syu --noconfirm
    type -q yay && yay -Syu --noconfirm
    type -q pnpm && pnpm update -g
    echo "✅ 完成"
end

# 一键清理缓存
function clean
    echo "🧹 清理中..."
    sudo pacman -Sc --noconfirm
    type -q yay && yay -Sc --noconfirm
    type -q pnpm && pnpm store prune
    echo "✅ 完成"
end

# git add + commit + push
function gacp
    test -z "$argv" && echo "用法: gacp \"信息\"" && return 1
    git add .; and git commit -m "$argv"; and git push
end

# 端口占用查看
function ports
    ss -tlnp | command grep -E "LISTEN|:"
end

# --- 历史 ---
# 注意：HISTSIZE/SAVEHIST/HISTCONTROL 是 bash/zsh 的变量，fish 不读取，
# 仅保留备查。fish 的历史持久化在 ~/.local/share/fish/fish_history，默认不限条数。
set -gx HISTSIZE 10000 SAVEHIST 10000 HISTCONTROL ignoredups:erasedups

# --- 缩写（按空格自动展开）---
abbr -a gco 'git checkout'
abbr -a gs 'git status'
abbr -a gc 'git commit -m'
abbr -a gp 'git push'
abbr -a .. 'cd ..'
abbr -a ... 'cd ../..'

# 动态切换 Neovim 配置：fzf 交互选择 default / nvim-react，
# 非 default 通过 NVIM_APPNAME 隔离成独立配置目录（~/.config/<名字>）
function nvs
    set -l items default nvim-react
    set -l config (string join \n $items | fzf --prompt="Select Neovim Profile: " --height=20% --layout=reverse --border)

    test -z "$config"; and return

    if test "$config" = default
        nvim $argv
    else
        env NVIM_APPNAME=$config nvim $argv
    end
end

# 设置默认文本颜色
set fish_color_normal normal
# 设置命令颜色
set fish_color_command blue
# 设置参数颜色
set fish_color_param cyan
# 设置引号颜色
set fish_color_quote yellow
# 设置重定向符号颜色
set fish_color_redirection magenta
# 设置注释颜色
set fish_color_comment brblack
# 设置自动建议的颜色
set fish_color_autosuggestion brblack
# 设置补全菜单选中项的颜色
set fish_color_selection --background=brblue
