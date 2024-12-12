# 更新日志

所有项目的重要更新都会记录在这个文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [1.0.0] - 2024-12-12

### 新增
- 支持 Event Stream 格式流式请求代理
- 支持非流式请求代理
- 实现多供应商聚合功能
  - 使用 Round Robin 算法进行负载均衡
  - 支持模型分组，可将多个实际模型映射到同一组名
- 添加基于 Bearer Token 的 API 密钥认证
- 实现响应中模型名称的一致性维护
- 配置文件自动热重载（60秒间隔）
- 高性能优化
  - 集成连接池机制
  - 支持长连接保持
  - 启用 TCP 优化（tcp_nopush, tcp_nodelay）

### 技术细节
- 基于 OpenResty 构建
- 支持 JSON 格式的配置文件
- 实现了完整的请求代理和响应处理流程
- 提供了清晰的配置文件格式和使用文档

[1.0.0]: https://github.com/z1o/OpenBridge/releases/tag/v1.0.0