# OpenBridge

OpenBridge 是一个基于 OpenResty 的轻量级、高性能的 OpenAI API 聚合工具。

## 功能特性

- 支持 Event Stream 格式流式请求代理和非流式请求代理
- 支持多供应商聚合，使用 Round Robin 算法进行负载均衡
- 支持模型分组功能，可将多个实际模型映射到同一个组名
- 支持基于 Bearer Token 的 API 密钥认证
- 自动维护响应中的模型名称一致性
- 配置文件自动热重载（每60秒）
- 高性能设计：
  - 使用连接池优化性能
  - 支持长连接保持
  - 启用 TCP 优化（tcp_nopush, tcp_nodelay）

## 安装说明

### 配置文件
配置文件为 JSON 格式，包含以下主要部分：

```json
{
    "providers": [
        {
            "group": "fast",
            "name": "gpt-4o-mini",
            "base": "https://api.openai.com",
            "key": "sk-abcdefghijklmnopqrstuvwxyz"
        }
    ],
    "security": [
        "sk-abcdefghijklmnopqrstuvwxyz"
    ]
}
```
各字段含义如下：
- `providers`: 供应商配置列表
  - `group`: 模型组名，客户端使用此名称访问
  - `name`: 实际模型名称，将被用于向上游服务发送请求
  - `base`: 供应商API的基础URL
  - `key`: 供应商的API密钥
- `security`: 允许访问的客户端Token列表

**默认配置文件的路径为 /app/config.json，请根据实际情况修改，并调整[lua/utils.lua](lua/utils.lua#L10)中的文件路径**

### 启动服务

```bash
git clone https://github.com/z1o/OpenBridge.git
cd OpenBridge
mkdir -p /app/lua
cat <<EOF > /app/config.json
{
    "providers": [
        {
            "group": "fast",
            "name": "gpt-4o-mini",
            "base": "https://api.openai.com",
            "key": "sk-abcdefghijklmnopqrstuvwxyz"
        }
    ],
    "security": [
        "sk-abcdefghijklmnopqrstuvwxyz"
    ]
}
EOF
mv /usr/local/openresty/nginx/conf/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf.bak
cp -r ./lua /app
cp ./conf/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
systemctl reload openresty
```

## 使用示例

### 非流式请求
```bash
curl -X POST http://localhost/v1/chat/completions \
-H "Authorization: Bearer sk-abcdefghijklmnopqrstuvwxyz" \
-H "Content-Type: application/json" \
-d '{
  "model": "fast",
  "messages": [{"role": "user", "content": "Hello!"}]
}'
```

### 流式请求
```bash
curl -X POST http://localhost/v1/chat/completions \
-H "Authorization: Bearer sk-abcdefghijklmnopqrstuvwxyz" \
-H "Content-Type: application/json" \
-N \
-d '{
  "model": "fast",
  "stream": true,
  "messages": [{"role": "user", "content": "Hello!"}]
}'
```

## 注意事项

1. 如果想要支持 `/v1/models` 接口，请自行实现
2. 所有请求必须包含有效的 Bearer Token 认证
3. 请求中的模型名称必须与配置文件中的某个组名匹配
4. 配置文件每60秒自动重新加载一次，支持热更新

## 更新日志

[CHANGELOG.md](CHANGELOG.md)

## 贡献指南

[CONTRIBUTING.md](CONTRIBUTING.md)

## 许可证

[LICENSE](LICENSE)
