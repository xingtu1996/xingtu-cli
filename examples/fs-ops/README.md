# fs-ops — 把高频运维操作封装成「人 + AI 通用」的统一 CLI

> 这是一个**可运行的骨架示例**，演示怎么把散落的脚本/手工操作封装成一条命令：
> `fs-ops log order-service --env uat --since 30m`。
>
> 设计目标不是某一个工具，而是让 **人直接用、AI Agent 也能直接 shell 调**——
> 省 token、省人工、统一认证和错误处理。

## 为什么需要这个

你每天重复做的事：查日志、查库、看部署状态、看 CI 结果。这些事通常散落在：
- 十几个独立脚本（每个一套参数、一套认证）
- 浏览器里点控制台（AI 够不着）
- 同事写的小工具（没人记得怎么用）

fs-ops 的做法：把这些高频操作聚成**一个入口、一套参数、一种输出**，
AI 读完 `fs-ops --help` 和 `commands/*.sh` 头部注释就能直接调用。

## 10 分钟跑通

```bash
# 1. 复制骨架到任意项目
mkdir -p ~/projects/demo/.claude/fs-ops
cp -r examples/fs-ops/* ~/projects/demo/.claude/fs-ops/
cd ~/projects/demo/.claude/fs-ops
chmod +x fs-ops commands/*.sh install.sh

# 2. 配 PATH
export PATH="$PWD:$PATH"

# 3. 验证骨架（demo 命令不调上游，纯演示）
fs-ops list
fs-ops demo order-service --env sit
fs-ops demo order-service --env uat --json
fs-ops auth status
```

你会看到：
- `list` 自动扫描 `commands/*.sh` 列出命令
- `demo --json` 输出结构化 JSON（Agent 可解析）
- 不带 `--env` 会被拦下来（防误操作）
- `auth status` 显示认证键位状态

## 目录结构

```
fs-ops/
├── fs-ops                 # 入口（命令注册表）
├── install.sh             # 一键安装到项目 .claude/fs-ops/
├── config.yaml.example    # 环境矩阵配置模板（复制为 config.yaml 填你的值）
├── lib/
│   ├── common.sh          # 错误码 / JSON 输出 / 参数解析 / 环境矩阵读取
│   └── auth.sh            # 认证状态汇总
├── commands/              # 命令（文件名 = 命令名，自动注册）
│   ├── _TEMPLATE.sh       # 新命令模板（拷贝即新增）
│   └── demo.sh            # 演示命令（可删）
└── docs/
    ├── architecture.md       # 三层架构 + 四形态演进
    └── packaging-tutorial.md # 封装教程（怎么把一个手工操作变成命令）
```

## 加你自己的命令

1. `cp commands/_TEMPLATE.sh commands/mylog.sh`
2. 把 `TOOL="your-tool"` 改成你在 `config.yaml` 里登记的工具名
3. 改 `run()`：调你真实的日志/数据库/CI API
4. `fs-ops list` 里自动出现 `mylog`——不需要改任何注册表

## 核心设计（详见 docs/）

- **命令自动注册**：扫描 `commands/*.sh`，文件名即命令名，零登记
- **`--env` 必填**：环境矩阵写在 config.yaml，工具不支持的环境直接报错，防 prod 误操作
- **`--json` 双模输出**：人读日志走 stdout，Agent 走结构化 JSON
- **统一错误码**：2 用法错误 / 3 认证缺失 / 4 未找到 / 5 上游失败——Agent 看到 code=3 就知道去查认证
- **认证收口**：所有 token 在 `~/.fs-ops.env`（0600），命令行不出现密码
- **零依赖**：bash 3.2 + python3 标准库，任何 macOS/Linux 能跑

## 适用边界

这是骨架，不是开箱即用的运维平台。你要：
- 在 `config.yaml` 里填**你自己项目的**环境 URL
- 把 `commands/` 里的 demo 换成**你真实的**日志/数据库/CI 调用
- 按需增删命令（命令多了自然形成你自己的 `fs-ops log/db/ci/...`）

方法论是通用的，工具本身绑定你的技术栈——**授人以渔，不是搬工具**。
