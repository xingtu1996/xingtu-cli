#!/bin/bash
# <你的命令名> — <一句话说明>（自动注册为 fs-ops <命令名>）
# ============================================================================
# fs-ops 命令模板 — 新增能力 = 拷贝本文件为 commands/<verb>.sh，改 run() 即可
#
# 自动注册: fs-ops 扫描 commands/*.sh，文件名即命令名（无需手动登记）
# 契约（必须实现）:
#   run "$@"         命令主函数（参数已过滤 --env/--json，存 FS_ENV/FS_REST）
# 可用工具（source 自 common.sh，入口已加载）:
#   fs_env_tool <tool>        读环境矩阵（JSON）
#   fs_env_tool_envs <tool>   工具支持的环境列表
#   fs_env_check <tool> <env> 校验工具+环境组合（不支持则 err）
#   require_env <env>         校验环境合法性（prod 写需确认）
#   fs_out <json>             统一成功输出
#   fs_err <code> <msg>        统一错误（exit）
#   fs_auth_get/require       认证读取
# 约束: bash 3.2+（无 declare -A/mapfile/${var,,}/globstar）
# ============================================================================

# 本命令作用的工具名（对应 config.yaml fs_ops.environments.<tool>）
TOOL="your-tool"

# 命令级帮助（fs-ops <verb> --help 触发）
usage() {
  cat <<EOF
用法: fs-ops ${0##*/} <target> [--env <sit|uat|prod>] [--json]
  例: fs-ops ${0##*/} example-service --env sit
说明: 一句话描述本命令做什么
EOF
}

run() {
  parse_common_args "$@"
  [ ${#FS_REST[@]} -eq 0 ] && usage && fs_err $FS_ERR_USAGE "缺少参数"

  # 1. 环境矩阵校验（工具支持哪些环境）
  local envs
  envs="$(fs_env_tool_envs "$TOOL")"
  fs_log "工具 ${TOOL} 支持环境: ${envs}（当前: ${FS_ENV:-未指定}）"

  # 2. 环境校验 + 认证
  require_env "${FS_ENV:-}"
  fs_env_check "$TOOL" "${FS_ENV:-}"

  # 3. 业务实现（此处填你的逻辑）
  # 例: 读环境矩阵 URL，调上游 API
  # local cfg
  # cfg="$(fs_env_tool "$TOOL")"
  # local url
  # url="$(echo "$cfg" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("url",""))')"

  fs_log "模板命令执行成功（替换为真实逻辑）"
  fs_out '{"ok":true,"message":"模板成功","tool":"'"$TOOL"'","env":"'"${FS_ENV:-}"'"}'
}
