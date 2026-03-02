# F-AI 财务助手

企业财务管理与 AI 分析平台，覆盖数据导入、报表生成、预算管理、异常预警、AI 财务助手、组织与权限管理等核心场景。

## 技术栈

- 前端：Vue 3 + Vite + TypeScript + Pinia + Vue Router + Ant Design Vue + ECharts
- 后端：FastAPI + SQLAlchemy + Pydantic
- 业务数据库：MySQL（默认）
- 系统配置持久化：SQLite（`backend/data/system_config.db`）
- AI：OpenAI 兼容接口（DeepSeek / 通义 / GLM 等）

## 系统详细功能

### 1. 认证与账户

- 用户注册、登录、JWT 鉴权
- 个人信息查看
- 用户头像、字体主题等系统设置（前端）

### 2. 企业与组织管理

- 创建企业、通过企业 ID 加入企业
- 企业成员列表查看
- 邀请企业成员加入（按用户名/邮箱）
- 成员移除、成员退出企业
- 超级管理员转移、企业解散

### 3. 权限管理（企业维度）

- 角色模型：
- `company_super_admin`（超级管理员）
- `admin`（企业管理员）
- `accountant` / `viewer`（普通成员）
- 权限规则：
- 超级管理员可设置企业管理员
- 企业管理员可分配除超级管理员外的成员权限
- 超级管理员与企业管理员可邀请成员、移除其他成员
- 普通成员不可管理企业和分配权限
- 前端路由与菜单按角色动态拦截（组织与权限管理页）

### 4. 财务数据管理

- Excel/CSV 批量导入财务记录
- 手工新增财务记录
- 财务记录分页、筛选、统计汇总
- 模板文件下载（导入模板）

### 5. 财务分析与可视化

- 收入趋势分析（`/financial/trend`）
- 现金流分析（`/financial/cashflow`）
- 支出分布、核心指标卡片、仪表盘展示

### 6. 报表管理

- 报表生成（利润表 / 资产负债表 / 现金流）
- 报表详情查看
- 报表导出（下载）
- AI 报表解读摘要

### 7. 预算管理

- 预算新增与列表管理
- AI 预算建议（LLM 推理）
- AI 预测结果（LLM 预测）
- 预算状态展示与执行跟踪

### 8. 异常预警

- 异常检测与结果展示
- 异常预警列表
- 预警已读处理
- AI 异常原因分析与建议

### 9. AI 财务助手

- 单轮 / 多轮财务问答
- 流式对话输出（SSE）
- 结合企业财务上下文生成分析结论
- 面向财务场景输出（避免开发者代码风格内容）

### 10. 系统配置中心（已持久化）

- AI 配置项：`base_url` / `api_key` / `model`
- 配置测试接口（返回 success / message / latency / model）
- 配置写入 SQLite，服务重启后仍生效

## 项目结构

```text
agent-master/
├─ frontend/                 # 前端工程
├─ backend/                  # 后端工程
│  ├─ app/
│  │  ├─ api/                # 路由层
│  │  ├─ models/             # 数据模型
│  │  ├─ schemas/            # 入参/出参模型
│  │  ├─ services/           # 业务服务层
│  │  └─ main.py             # FastAPI 入口
│  └─ data/system_config.db  # 系统配置 SQLite
└─ sql/                      # MySQL 初始化/迁移 SQL
```

## 快速启动

### 1) 启动后端

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

后端地址：`http://localhost:8000`

### 2) 启动前端

```bash
cd frontend
npm install
npm run dev
```

前端地址：`http://localhost:5173`

> Vite 已配置 `/api -> http://localhost:8000` 代理。

## 环境变量（后端）

`backend/.env` 示例：

```env
DATABASE_URL=mysql+pymysql://root:password@localhost:3306/fai_db
SECRET_KEY=dev-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440

LLM_API_KEY=
LLM_BASE_URL=https://api.deepseek.com/v1
LLM_MODEL=deepseek-chat
```

## 核心接口分组

- 认证：`/api/auth/*`
- 用户与企业：`/api/users/*`
- 财务数据：`/api/financial/*`
- 报表：`/api/reports/*`
- AI：`/api/ai/*`

详细说明见：
- [系统开发文档](./docs/系统开发文档.md)

## 注意事项

- 前端 `npm run build` 使用 `vue-tsc && vite build`。若本机 `vue-tsc` 与 Node 版本兼容异常，可先用 `npx vite build` 验证打包。
- AI 系统配置已做 SQLite 持久化，重启后端后配置不会丢失。

