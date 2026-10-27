#!/bin/bash
# ============================================================================
# fs-ops 公共库 — 错误码 / JSON 输出 / 参数解析 / 环境矩阵读取
# 用法: source "${FS_OPS_LIB}/common.sh"
# 约束: bash 3.2+（禁 bash4: declare -A/mapfile/${var,,}/globstar）
#       仅 python3 标准库（无第三方依赖）
# ============================================================================

# --- 错误码（Agent 可据此自愈）------------------------------------------
FS_OK=0
FS_ERR_GENERAL=1
FS_ERR_USAGE=2
FS_ERR_AUTH=3
FS_ERR_NOTFOUND=4
FS_ERR_UPSTREAM=5

# --- 输出 ------------------------------------------------------------
# fs_out <json-string>         统一成功输出
# fs_err <code> <msg>          统一错误（含类型/码/修复提示），exit code
# fs_log <msg>                 普通日志（非 JSON 模式走 stdout）
FS_JSON_MODE=0

fs_is_json() {
  [ "${FS_JSON_MODE}" = "1" ]
}

fs_log() {
  if fs_is_json; then
    : # JSON 模式不混入日志，由调用方组装
  else
    echo "$1"
  fi
}

fs_out() {
  if fs_is_json; then
    echo "$1"
  else
    # 从 JSON 提取 message 字段显示（简单提取，复杂用 python3）
    echo "$1" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("message","ok"))' 2>/dev/null || echo "$1"
  fi
}

fs_err() {
  local code="$1"; local msg="$2"
  if fs_is_json; then
    printf '{"ok":false,"code":%s,"message":"%s"}\n' "$code" "$msg"
  else
    echo "[code=$code] $msg" >&2
    echo "  hint: add --json for structured error; auth issue: fs-ops auth status" >&2
  fi
  exit "$code"
}

# --- 参数解析 ----------------------------------------------------------
# 解析通用参数: --env <env> --json
# 设 FS_ENV / FS_JSON_MODE，从参数中剔除这两个，剩余存 FS_REST
# 注意: bash3.2 无关联数组，用全局变量
FS_ENV=""
FS_REST=()
parse_common_args() {
  local args=("$@")
  FS_REST=()
  local i=0
  while [ $i -lt ${#args[@]} ]; do
    case "${args[$i]}" in
      --env)
        i=$((i+1))
        [ $i -ge ${#args[@]} ] && fs_err $FS_ERR_USAGE "--env 需要一个值（sit/uat/prod）"
        FS_ENV="${args[$i]}"
        ;;
      --json) FS_JSON_MODE=1 ;;
      *)
        FS_REST+=("${args[$i]}")
        ;;
    esac
    i=$((i+1))
  done
}

# 校验环境是否在允许集内；prod 写操作需确认
# require_env <env> [allow_prod_write]
require_env() {
  local env="$1"; local allow_write="${2:-0}"
  case "$env" in
    sit|uat|prod|local|dev) ;;
    *) fs_err $FS_ERR_USAGE "环境必须是 sit/uat/prod（收到: ${env:-空}）。防误用，--env 必填" ;;
  esac
  if [ "$env" = "prod" ] && [ "$allow_write" = "0" ]; then
    fs_err $FS_ERR_USAGE "prod 环境操作需显式确认。只读可加 --env prod；写操作需人工审批"
  fi
}

# --- 环境矩阵读取（config.yaml fs_ops 节）-----------------------------
# 读 fs_ops.environments.<tool> 的环境/URL/认证信息
# fs_env_tool <tool>           输出该工具配置（JSON）
# fs_env_tool_envs <tool>      输出支持的环境列表（空格分隔）
# fs_env_check <tool> <env>    校验工具是否支持该环境，不支持则 err
fs_env_file="${FS_OPS_CONFIG:-${FS_OPS_DIR}/config.yaml}"

# 提取 fs_ops 节某工具配置（python3 标准库，兼容简单 YAML）
fs_env_tool() {
  local tool="$1"
  python3 - "$fs_env_file" "$tool" <<'PYEOF'
import sys, re, json

def main():
    fname, tool = sys.argv[1], sys.argv[2]
    def normalize(s):
        d = {}
        m = re.search(r"envs:\s*\[([^\]]*)\]", s)
        if m:
            d["envs"] = [x.strip() for x in m.group(1).split(",") if x.strip()]
        for key in ("url", "space", "region", "index", "auth", "note", "login_url"):
            m = re.search(r"\b" + key + r":\s*\"([^\"]*)\"", s)
            if m:
                d[key] = m.group(1)
        return json.dumps(d, ensure_ascii=False)
    try:
        content = open(fname, encoding='utf-8').read()
    except Exception:
        print(json.dumps({'error': 'read config failed'})); return
    for line in content.splitlines():
        m = re.match(r'^\s+([a-z_]+):\s*(\{.*\})\s*$', line)
        if not m:
            continue
        name, val = m.group(1), m.group(2)
        if name == tool and 'envs' in val:
            print(normalize(val)); return
    print('{}')

main()
PYEOF
}

# 输出工具支持的环境列表（空格分隔）
fs_env_tool_envs() {
  local tool="$1"
  fs_env_tool "$tool" | python3 -c 'import sys,json
try:
    d=json.load(sys.stdin)
    print(" ".join(d.get("envs",[])))
except Exception:
    print("")'
}

# 校验工具 + 环境组合
fs_env_check() {
  local tool="$1"; local env="$2"
  [ -z "$env" ] && fs_err $FS_ERR_USAGE "缺少 --env（工具 ${tool} 需指定环境）"
  local envs
  envs="$(fs_env_tool_envs "$tool")"
  echo "$envs" | grep -qw "$env" || fs_err $FS_ERR_USAGE "工具 ${tool} 不支持环境 ${env}（支持: ${envs}）"
}

# --- 认证文件 ----------------------------------------------------------
# fs_auth_get <key>      读 ~/.fs-ops.env 的 key（0600 权限文件）
# fs_auth_require <key>  读不到则 err（提示 auth status）
fs_auth_get() {
  local key="$1"
  if [ ! -f "${FS_OPS_ENV_FILE:-$HOME/.fs-ops.env}" ]; then
    echo ""
    return 1
  fi
  grep -E "^${key}=" "${FS_OPS_ENV_FILE}" 2>/dev/null | head -1 | cut -d= -f2-
}

fs_auth_require() {
  local key="$1"; local tool="$2"
  local v
  v="$(fs_auth_get "$key")"
  if [ -z "$v" ]; then
    fs_err $FS_ERR_AUTH "缺少认证 ${key}（工具 ${tool}）。运行 fs-ops auth status 查看，或写入 ~/.fs-ops.env"
  fi
  echo "$v"
}
