# 封装教程：把一个手工操作变成 AI 友好命令

## Step 1：识别高频操作

先问自己：**我每周重复做 ≥3 次的手工操作是什么？**

- 查某个服务的日志？
- 连数据库跑固定 SQL？
- 看 CI 构建状态？
- 看 K8s 部署到哪个版本了？

从最高频、最痛的那个开始。YAGNI——不高频的先不封装。

## Step 2：沉淀五要素

在动手写脚本前，把这五件事写清楚（缺一个都不要开始）：

| 要素 | 说明 | 例子 |
|------|------|------|
| 地址 | 目标系统的 URL | `https://kibana-uat.example.com` |
| 用途 | 这工具干什么 | 查 order-service 的错误日志 |
| 用法 | 怎么调用 | 浏览器输入关键词 / 跑 curl |
| 认证 | 怎么鉴权 | 零认证 / OAuth / cookie / token |
| 上游 API | 底层实际调什么 | `GET /_search?q=service:order-service` |

**关键动作**：打开浏览器 F12，把你点控制台时发的那个请求抄成 curl。
这是整个封装里最花时间的一步，但也是最有价值的一步——
一旦你能 curl，AI 就能调。

## Step 3：套模板改成命令

```bash
cp commands/_TEMPLATE.sh commands/mylog.sh
```

打开 `commands/mylog.sh`，改三处：

1. **`TOOL`**：填你在 `config.yaml` 里登记的工具名（比如 `kibana`）
2. **`usage()`**：写清楚用法和例子
3. **`run()`**：把 curl 逻辑填进去

```bash
run() {
  parse_common_args "$@"
  [ ${#FS_REST[@]} -eq 0 ] && usage && fs_err $FS_ERR_USAGE "缺少服务名"

  local service="${FS_REST[0]}"

  # 1. 环境校验（防 prod 误用）
  require_env "${FS_ENV:-}"
  fs_env_check "kibana" "${FS_ENV:-}"

  # 2. 读环境矩阵拿到 URL
  local cfg; cfg="$(fs_env_tool "kibana")"
  local url; url="$(echo "$cfg" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("url",""))')"

  # 3. 调上游（这里换成你 F12 抄来的 curl）
  local result
  result="$(curl -s "${url}/_search?q=service:${service}" | head -100)"

  # 4. 输出
  fs_log "查到 ${service} 在 ${FS_ENV} 的最近日志"
  fs_out "{\"ok\":true,\"message\":\"${result}\"}"
}
```

## Step 4：登记环境矩阵

在 `config.yaml` 的 `fs_ops.environments` 下加一段：

```yaml
fs_ops:
  environments:
    kibana:
      envs: [sit]
      url: "https://kibana-sit.example.com"
      auth: none
```

这样 `fs-ops mylog order-service --env sit` 会自动校验：
- sit 是合法环境
- kibana 支持 sit

如果有人敲 `fs-ops mylog order-service --env prod`，直接报错。

## Step 5：认证收口（如果需要）

如果上游要 token：

1. 在 `~/.fs-ops.env` 里加一行：`export MYTOOL_TOKEN=<你的token>`
2. 命令里用 `fs_auth_require "MYTOOL_TOKEN" "mytool"` 取
3. `fs-ops auth status` 自动显示这个键配没配

**不要**把 token 写进命令行、config.yaml、或者 git。

## Step 6：验证

```bash
fs-ops list                              # 看到 mylog 自动出现
fs-ops mylog order-service --env sit     # 人读模式
fs-ops mylog order-service --env sit --json   # JSON 模式
fs-ops mylog                             # 不带 --env，应该被拦
fs-ops mylog order-service --env prod     # 不支持的环境，应该报错
```

## Step 7：组合成 Skill（命令稳定后再做）

当你有 3+ 个命令稳定了，把它们串成工作流（比如"发版"= ci 构建 → ops 看部署 → log 查日志），
写一个 `.claude/skills/release/SKILL.md`，让 AI 用自然语言触发整个流程。

**命令没稳定前不要急着做 Skill**——先让命令本身好用。

## 自查清单（提交前过一遍）

```
[ ] 这个操作每周重复 ≥3 次？（否则 YAGNI）
[ ] 五要素齐了吗？（地址/用途/用法/认证/上游 API）
[ ] --env 必填了吗？（防环境误用）
[ ] --json 输出了吗？（Agent 友好）
[ ] 写守卫/确认有吗？（prod 安全）
[ ] token 走 ~/.fs-ops.env 了吗？（不进 git）
[ ] 头部注释写清楚了吗？（他人/AI 能逆向）
[ ] 零依赖吗？（bash3.2 + python3 标准库）
```
