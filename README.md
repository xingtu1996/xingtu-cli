# XingTu CLI · 零依赖开发者命令行工具

> 纯 Shell / Python 标准库实现，零第三方依赖，即拉即用。

![MIT](https://img.shields.io/badge/license-MIT-green.svg)

## 这是什么

`xingtu-cli` 是行途开源矩阵的 **CLI 工具资产仓**。收录零依赖、可独立执行的命令行工具：Claude Code 多 provider 配置管理、文件操作安全护栏、环境自检。

## 工具清单

| 工具 | 说明 |
|------|------|
| scripts/cc-switch-add-tokenhub.py | 把 TokenHub 供应商写入 cc-switch，一键切换 Claude Code 模型网关 |
| scripts/cc-switch-sync-profiles.py | 基于真实 `~/.claude/settings.json` 同步多 provider profiles（保留 hooks/statusLine/theme）|
| scripts/backup-before-op.sh | 危险操作前自动备份（安全护栏）|
| scripts/safe-delete.sh | 安全删除：进回收站/确认，避免误删 |
| scripts/env-check.sh | 开发环境自检（依赖/版本/路径）|

## 用法

```bash
# 配置管理：把 TokenHub 网关加入 cc-switch（密钥走环境变量，不落盘）
TOKENHUB_API_KEY=你的Key python3 scripts/cc-switch-add-tokenhub.py

# 安全护栏
bash scripts/backup-before-op.sh target/
bash scripts/safe-delete.sh file.txt

# 环境自检
bash scripts/env-check.sh
```

## 安全设计

- 密钥/Token 一律走环境变量（`TOKENHUB_API_KEY` / `ANTHROPIC_API_KEY`），**不硬编码、不落盘**
- 网关鉴权用占位符 + 真鉴权走网关侧 `TOKENHUB_API_KEY`
- 危险操作（删除/覆盖）内置备份与确认

## 目录结构

```
scripts/   # CLI 工具（Python 标准库 / bash，零第三方依赖）
```

## 许可证

MIT License
