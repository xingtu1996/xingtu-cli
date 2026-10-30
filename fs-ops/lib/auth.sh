#!/bin/bash
# ============================================================================
# fs-ops 认证 — 统一查看 ~/.fs-ops.env 各能力认证状态
# 用法: fs-ops auth status
# ============================================================================

fs_auth_status() {
  local env_file="${FS_OPS_ENV_FILE:-$HOME/.fs-ops.env}"
  if [ ! -f "$env_file" ]; then
    echo "~/.fs-ops.env 不存在 — 认证未配置"
    echo ""
    echo "创建 ${env_file}（权限 0600）并填入示例键:"
    echo "  export ALIYUN_PROFILE=<profile>    # aliyun OAuth（SLS 日志）"
    echo "  export JENKINS_API_TOKEN=<token>    # Jenkins API Token"
    echo "  export DB_USER=<user>               # 数据库账号"
    echo "  export RANCHER_TOKEN=<api-key>      # Rancher API Key"
    exit $FS_ERR_AUTH
  fi

  # 检查文件权限
  local perm
  perm="$(stat -f "%Lp" "$env_file" 2>/dev/null || echo "?")"
  echo "认证文件: ${env_file} (权限 ${perm})"
  echo ""
  local key desc
  # 示例键位：按你项目实际接入的工具增删
  for kv in \
    "ALIYUN_PROFILE:aliyun OAuth（SLS 日志）" \
    "JENKINS_API_TOKEN:Jenkins API Token（CI）" \
    "DB_USER:数据库账号（只读查询）" \
    "RANCHER_TOKEN:Rancher API Key（部署状态）"
  do
    key="${kv%%:*}"
    desc="${kv#*:}"
    local val
    val="$(fs_auth_get "${key}")"
    if [ -n "$val" ]; then
      echo "  [ok]   ${key} — ${desc}"
    else
      echo "  [--]   ${key} — ${desc}（未配置）"
    fi
  done
  echo ""
  echo "认证演进: 个人 token -> 项目组 AI 账号（限权+审批）-> 中央 MCP Server"
}

fs_auth_main() {
  local sub="${1:-status}"; shift 2>/dev/null || true
  case "$sub" in
    status) fs_auth_status ;;
    *) fs_err $FS_ERR_USAGE "auth 子命令: status" ;;
  esac
}
