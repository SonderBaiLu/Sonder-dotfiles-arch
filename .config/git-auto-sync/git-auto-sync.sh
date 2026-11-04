#!/usr/bin/env bash
# 定时把仓库改动 add / commit / push 到 GitHub
# 用法: git-auto-sync.sh [--dry-run]
set -uo pipefail

REPOS=(
  "$HOME/Documents/Rust项目/Rust_Blog"
  "$HOME/Documents/Vue项目/Vue_blog_front-end"
  "$HOME/Documents/learning"
  "$HOME/Sonder-dotfiles-arch"
)
MSG="自动生成"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }

# 本地领先上游时推送；没有上游或已同步则跳过
push_repo() {
  local name="$1"
  if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    log "[warn] $name: 没有上游分支，跳过 push"
    return
  fi
  if [ "$(git rev-list --count '@{u}..HEAD')" -eq 0 ]; then
    return
  fi
  if [ "$DRY_RUN" = "1" ]; then
    log "[dry-run] $name: 有未推送提交，将 push"
    return
  fi
  if git push -q; then
    log "[push] $name: 已推送"
  else
    log "[error] $name: git push 失败"
  fi
}

for repo in "${REPOS[@]}"; do
  name="$(basename "$repo")"

  if [ ! -d "$repo/.git" ]; then
    log "[skip] $name: 不是 git 仓库"
    continue
  fi
  cd "$repo" || { log "[skip] $name: 无法进入目录"; continue; }

  # merge / rebase / cherry-pick 等中途状态一律不碰，避免提交半成品
  if git rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1 \
     || [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ] \
     || [ -f .git/CHERRY_PICK_HEAD ] || [ -f .git/REVERT_HEAD ]; then
    log "[skip] $name: 处于 merge/rebase/cherry-pick 中途"
    continue
  fi
  if git status --porcelain | grep -qE '^(DD|AU|UD|UA|DU|AA|UU) '; then
    log "[skip] $name: 存在未解决冲突"
    continue
  fi

  # 工作区干净：只补推可能存在的未推送提交
  if [ -z "$(git status --porcelain)" ]; then
    push_repo "$name"
    continue
  fi

  if [ "$DRY_RUN" = "1" ]; then
    log "[dry-run] $name: 有改动，将 add/commit/push"
    continue
  fi

  if ! git add -A; then
    log "[error] $name: git add 失败"
    continue
  fi
  if git diff --cached --quiet; then
    continue
  fi
  if ! git commit -q -m "$MSG"; then
    log "[error] $name: git commit 失败"
    continue
  fi
  log "[commit] $name: $(git log -1 --format='%h %s')"

  push_repo "$name"
done
