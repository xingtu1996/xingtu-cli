# xingtu-cli — 服务于 AI Agent 的终端操作接口集

> 从真实生产 harness 里蒸馏出来的 CLI 工具集：我们自己开发的命令行、日常在用的工具、以及把手工操作封装成 CLI 的方法论。
> 核心理念：**封装为 Agent 而生**——纯文本交互，人直接用、AI 读个 `--help` 就能 shell 调，省 token、省人工。

## 这个仓收录什么

三类内容：

| 类别 | 是什么 | 例子 |
|------|--------|------|
| **我们开发的 CLI** | 自己写的、每天在项目里跑的命令行工具 | [`fs-ops/`](./fs-ops/)（统一运维 CLI）、[`scripts/`](./scripts/)（safe-delete/env-check/cc-switch） |
| **我们使用过的 CLI** | 日常在用的工具及配置/封装经验 | 各 CLI 的环境配置、与 AI Agent 配合的用法 |
| **封装 CLI 的方法** | 怎么从手工操作变成 AI 友好的命令行 | [`docs/cli-architecture.md`](./docs/cli-architecture.md)（三层架构）、[`docs/packaging-tutorial.md`](./docs/packaging-tutorial.md)（七步封装法） |

> 配套的 Skill（工作流编排层）在独立仓 [xingtu-skills](https://github.com/xingtu1996/xingtu-skills) 管理，本仓聚焦 CLI 本身。

## 工具清单

### 我们开发的 CLI

| 位置 | 工具 | 说明 |
|------|------|------|
| [`fs-ops/`](./fs-ops/) | 统一运维 CLI | 把日志/数据库/CI/部署/健康检查聚成一条命令，人+AI 通用。带可运行骨架 + 封装教程 |
| [`scripts/safe-delete.sh`](./scripts/safe-delete.sh) | 安全删除 | 进回收站而非硬删，防误删 |
| [`scripts/backup-before-op.sh`](./scripts/backup-before-op.sh) | 操作前备份 | 批量/结构性改动前打快照 |
| [`scripts/env-check.sh`](./scripts/env-check.sh) | 环境检查 | 依赖/版本/路径体检 |
| [`scripts/cc-switch-*.py`](./scripts/) | Claude Code 配置切换 | 多 profile 同步 / token 接入 |

### 封装方法论

| 文档 | 内容 |
|------|------|
| [`docs/cli-architecture.md`](./docs/cli-architecture.md) | 三层架构（编排 Skill / 能力 CLI / 基础环境矩阵+认证）+ 四形态演进（bash→CLI→Skill→MCP） |
| [`docs/packaging-tutorial.md`](./docs/packaging-tutorial.md) | 七步封装法：识别高频操作 → 沉淀五要素 → 套模板 → AI 友好化 → 组合成 Skill |

## 快速开始：fs-ops（10 分钟跑通）

```bash
# 1. 复制骨架
cp -r fs-ops /tmp/fs-ops-demo
cd /tmp/fs-ops-demo
chmod +x fs-ops commands/*.sh

# 2. 跑通（demo 命令不调任何上游，纯演示）
./fs-ops list
./fs-ops demo order-service --env sit
./fs-ops demo order-service --env uat --json
```

你会看到：
- `list` 自动扫描 `commands/*.sh`，文件名即命令名，零注册
- `--json` 输出结构化 JSON，Agent 可解析
- 不带 `--env` 直接被拦（防 prod 误操作）

**把它改成你自己的命令**：`cp commands/_TEMPLATE.sh commands/mylog.sh`，改 `run()` 调你的 API，自动成为 `fs-ops mylog`。

## 为什么这么设计

- **命令自动注册**：扫描 `commands/*.sh`，加文件 = 加命令，零框架
- **`--env` 必填 + 环境矩阵**：工具不支持的环境直接报错，从机制上防误操作
- **`--json` 双模输出**：人读日志 / Agent 读 JSON，统一错误码（2 用法/3 认证/4 未找到/5 上游）
- **认证收口**：所有 token 在 `~/.fs-ops.env`（0600），不进命令行、不进 git
- **零依赖**：bash 3.2 + python3 标准库，任何 macOS/Linux 能跑
- **四形态演进**：bash 脚本（个人）→ CLI（团队）→ Skill（工作流）→ MCP（全组），不一步到位

详见 [`docs/cli-architecture.md`](./docs/cli-architecture.md)。

## Roadmap

- [x] fs-ops 完整骨架（入口 + 模板 + demo + 教程）
- [ ] 更多通用命令示例（健康检查、日志查询的通用写法）
- [ ] 日常在用 CLI 的配置与封装经验归档
- [ ] Skill 编排层示例（把多命令组合成工作流，配套 xingtu-skills 仓）

## 许可证

MIT License

---

## 关于作者 · 行途 XingTu

- 公众号「行途技术手记」（长文首发，微信搜索关注）
- GitHub：[@xingtu1996](https://github.com/xingtu1996)
- 方法论旗舰仓：[xingtu-ai-engineering](https://github.com/xingtu1996/xingtu-ai-engineering)
- 工具集聚合镜像：[xingtu-tools](https://github.com/xingtu1996/xingtu-tools)（本仓 CLI 的镜像收录，权威源在本仓）
- 开源矩阵：[xingtu1996](https://github.com/xingtu1996) — AI 工程化 / Agent Harness / 省 Token 实践
