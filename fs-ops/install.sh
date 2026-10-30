#!/bin/bash
# ============================================================================
# fs-ops 一键安装 — 复制到项目 + 配 PATH + 认证模板
# 用法: bash install.sh [项目目录]
# 例:   bash install.sh ~/projects/my-project
# ============================================================================
set -euo pipefail

# 目标目录（默认当前 fs-ops 所在项目的 .claude/fs-ops）
TARGET="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
INSTALL_DIR="$TARGET/.claude/fs-ops"

echo "==> fs-ops 安装到: $INSTALL_DIR"

# 1. 复制自身到目标 .claude/fs-ops
mkdir -p "$INSTALL_DIR"
cp -r "$(dirname "$0")/lib" "$(dirname "$0")/commands" "$(dirname "$0")/fs-ops" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/fs-ops" "$INSTALL_DIR"/commands/*.sh
echo "  CLI 复制完成"

# 2. 配置模板（存在则不覆盖）
if [ ! -f "$INSTALL_DIR/config.yaml" ]; then
  cp "$(dirname "$0")/config.yaml.example" "$INSTALL_DIR/config.yaml"
  echo "  配置模板已生成（编辑 config.yaml 填你的环境矩阵）"
else
  echo "  config.yaml 已存在，跳过"
fi

# 3. 认证模板
if [ ! -f "$HOME/.fs-ops.env" ]; then
  cat > "$HOME/.fs-ops.env" <<'EOF'
# fs-ops 认证（权限 0600）
# ALIYUN_PROFILE=<profile>          # aliyun OAuth（SLS 日志）
# JENKINS_API_TOKEN=<token>          # Jenkins API Token
# DB_USER=<user>                     # 数据库账号
# RANCHER_TOKEN=<api-key>            # Rancher API Key
EOF
  chmod 600 "$HOME/.fs-ops.env"
  echo "  ~/.fs-ops.env 模板已生成（填入各能力 token）"
else
  echo "  ~/.fs-ops.env 已存在，跳过"
fi

# 4. PATH 提示
echo ""
echo "==> 添加 PATH（追加到 ~/.zshrc 或 ~/.bashrc）:"
echo "    export PATH=\"$INSTALL_DIR:\$PATH\""
echo ""
echo "==> 验证:"
echo "    fs-ops list"
echo "    fs-ops auth status"
echo "    fs-ops demo order-service --env sit --json"
echo ""
echo "==> 安装完成。新成员 10 分钟开箱即用。"
