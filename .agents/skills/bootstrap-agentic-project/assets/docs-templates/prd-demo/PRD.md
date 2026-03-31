# Demo 需求：用户登录模块

## 1. 业务背景
为了保障用户数据安全，我们需要重构当前的登录模块，支持手机号验证码登录与密码登录。

## 2. 业务流程图 (Mermaid)

```mermaid
flowchart TD
    A[用户进入登录页] --> B{选择登录方式}
    B -->|手机号验证码| C[输入手机号]
    C --> D[获取验证码]
    D --> E[输入验证码]
    B -->|账号密码| F[输入账号密码]
    E --> G{校验通过?}
    F --> G
    G -->|是| H[跳转 Dashboard]
    G -->|否| I[显示错误提示]
```

## 3. 时序图演示 (PlantUML)

```plantuml
@startuml
actor 用户 as user
participant "前端客户端" as client
participant "网关网关" as gateway
participant "认证服务" as auth

user -> client: 输入手机号与验证码
client -> gateway: POST /api/login
gateway -> auth: 转发请求
auth -> auth: 校验验证码与手机号
alt 校验成功
    auth --> gateway: 返回 Token (200 OK)
    gateway --> client: 响应登录成功
    client -> user: 跳转 Dashboard
else 校验失败
    auth --> gateway: 返回错误信息 (401 Unauthorized)
    gateway --> client: 响应错误
    client -> user: 提示错误原因
end
@enduml
```

## 4. 核心功能点
- 手机号 + 验证码登录 (默认)
- 账号 + 密码登录
- 忘记密码流程

## 4. 验收标准
- [ ] 手机号格式校验错误时，输入框下方显示红色提示。
- [ ] 验证码发送后需有 60s 倒计时。
- [ ] 登录成功后跳转到 `/dashboard`。

## 5. UI/UX 专注测试
> 👉 请使用右侧顶部的下拉菜单切换原型视角 (Focus Mode)，测试对应的组件状态。
