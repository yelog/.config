#!/bin/bash
# 获取项目名（优先 Git 仓库名，其次目录名）
get_project_name() {
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$git_root" ]]; then
    basename "$git_root" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
  else
    basename "$PWD" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
  fi
}

# 设置标题
kitty @ set-tab-title "NVIM:$(get_project_name)"
