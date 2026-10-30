#!/bin/bash
# demo — 演示命令：展示 AI 友好 CLI 的标准写法（从 _TEMPLATE.sh 改造）
# ============================================================================
# 这是一个可运行的示例命令，不真正调上游 API，只演示：
#   1. --env 必填 + 环境矩阵校验
#   2. --json 结构化输出
#   3. 统一错误码
#   4. 人读日志 / JSON 双模式
# 你删掉本文件之前，先用它验证 fs-ops list / fs-ops demo --json 能跑通。
# ============================================================================

TOOL="demo"

usage() {
  cat <<EOF
用法: fs-ops demo <service> [--env <sit|uat|prod>] [--json]
  例: fs-ops demo order-service --env uat --json
说明: 不调上游，只演示参数解析 / 环境校验 / JSON 输出 / 错误码
EOF
}

run() {
  parse_common_args "$@"
  [ ${#FS_REST[@]} -eq 0 ] && usage && fs_err $FS_ERR_USAGE "缺少服务名，例: fs-ops demo order-service --env sit"

  local service="${FS_REST[0]}"

  # 1. 环境校验（不查环境矩阵，直接用 require_env 防 prod 误用）
  require_env "${FS_ENV:-}"

  # 2. 演示人读日志（--json 模式下自动静默）
  fs_log "查询服务 [${service}] 在 [${FS_ENV:-未指定环境}] 环境..."

  # 3. 演示模拟上游返回（真实命令在这里 curl 你的日志/数据库/CI API）
  #    这里直接拼 JSON，让 --json 能看到结构化输出（零依赖）
  local env="${FS_ENV:-}"
  fs_out "{\"ok\":true,\"message\":\"demo: ${service} @ ${env}\",\"service\":\"${service}\",\"env\":\"${env}\",\"events\":[{\"level\":\"INFO\",\"msg\":\"service started\"},{\"level\":\"WARN\",\"msg\":\"memory usage 82%\"}]}"
}
