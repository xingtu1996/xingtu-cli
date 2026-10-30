# 架构速览：三层职责 + 四形态演进

## 一、三层架构

```
人 / AI Agent
   │
   ▼
┌─────────────────────────────────────────────┐
│ 编排层  Skill: release / e2e / troubleshoot  │  ← 组合命令成工作流
├─────────────────────────────────────────────┤
│ 能力层  CLI fs-ops（log/db/ci/ops/health…）   │  ← 统一入口，人+AI 通用
├─────────────────────────────────────────────┤
│ 基础层  环境矩阵（config.yaml）+ 认证（env） │  ← 单一事实源
└─────────────────────────────────────────────┘
```

| 层 | 职责 | 例子 |
|----|------|------|
| 编排层 | 把多命令组合成"工作流" | `release`（构建→部署→验证） |
| 能力层 | 每条命令一件事，统一参数/输出 | `fs-ops log order-service --env uat` |
| 基础层 | 环境不散落、认证集中 | `config.yaml` fs_ops 节 + `~/.fs-ops.env` |

**运维链路**：`health`（注册/健康）→ `ops`（部署）→ `log`（日志）→ `db`（数据）。

## 二、关键设计决策

### 1. 环境矩阵：工具 ≠ 所有环境都能用

不是所有工具都同时能连 sit/uat/prod。在 `config.yaml` 里显式登记每个工具支持哪些环境：

```yaml
fs_ops:
  environments:
    sls:
      envs: [uat, prod]        # SLS 只在 uat/prod
    kibana:
      envs: [sit]              # Kibana 只在 sit
    db:
      envs: [local, sit, uat]  # 数据库不碰 prod
```

命令侧强制 `--env` 必填，且 `fs_env_check` 校验工具+环境组合——
`fs-ops db something --env prod` 直接报错，从机制上防误操作。

### 2. 统一输出：人可读 + `--json` 结构化

- 默认模式：人读，`fs_log` 输出提示
- `--json` 模式：只输出结构化 JSON，日志自动静默
- 错误统一走 `fs_err <code> <msg>`，JSON 模式下输出 `{"ok":false,"code":3,"message":"..."}`

Agent 不需要猜输出格式，`--json` 就能解析。

### 3. 统一错误码（Agent 可自愈）

| code | 含义 | Agent 该怎么办 |
|------|------|---------------|
| 2 | 用法错误 | 自己读 help 改参数 |
| 3 | 认证缺失 | 提示用户配 `~/.fs-ops.env` |
| 4 | 资源未找到 | 检查服务名/环境 |
| 5 | 上游失败 | 重试或报错给人 |

### 4. 插件化：文件名即命令名

```bash
cp commands/_TEMPLATE.sh commands/mylog.sh
# 自动成为 fs-ops mylog，无需注册
```

入口脚本扫描 `commands/*.sh`，每个文件头部注释里取第一行带 `—` 的说明显示在 `list` 里。
新增命令 = 加一个文件，零框架、零配置。

### 5. 认证收口

- 所有 token 统一放 `~/.fs-ops.env`（权限 0600）
- 命令里用 `fs_auth_require "JENKINS_API_TOKEN" "jenkins"` 取，取不到直接 code=3
- 密码不进命令行、不进 config.yaml、不进 git

## 三、四形态演进（不要一步到位）

| 阶段 | 形态 | 门槛 | 什么时候用 |
|------|------|:---:|------|
| **L1** | bash 脚本（个人） | 零依赖，今天就能写 | 你自己每周重复 ≥3 次的操作 |
| **L2** | CLI 封装（团队） | 中等，套本仓库骨架 | 2+ 人高频用、需要统一参数 |
| **L3** | Skill 组合（工作流） | 低，写个 SKILL.md | 命令稳定后，把多命令串成流程 |
| **L4** | MCP Server（全组） | 高，起个服务 | 外部 AI 平台/Dify/LangChain 要接 |

**反模式**：一上来就搭 CLI 框架（Cobra/picocli）或上 MCP——没验证价值就过度建设。
先从一条 bash 命令开始，见利后再升级。

## 四、AI 友好的 5 个要点

判断你的命令"AI 能不能直接用"，看这五条：

1. **纯文本交互**：参数 + stdout，Agent 能 shell 直调
2. **`--json` 输出**：结构化，Agent 可解析
3. **统一错误码**：Agent 看 code 就知道怎么自愈
4. **头部注释清晰**：用法/环境/认证写全，Agent 读注释即懂
5. **零依赖**：bash3.2 + python3 标准库，任何机器能跑
