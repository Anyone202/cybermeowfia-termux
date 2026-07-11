# CyberMeowfia Termux Root Manager

基于 CVE-2026-43501 内核漏洞的 Termux 提权工具与 Root 权限管理器。

## 功能

- CVE-2026-43501 内核漏洞利用
- Flask Web 管理界面 (25 个 API)
- HMAC-SHA256 令牌认证
- 进程管理、文件系统访问
- Magisk 模块与授权管理
- Root 隐藏 (DenyList/Zygisk 检测)

## 安装

```bash
bash scripts/install.sh
```

## 运行

```bash
bash scripts/start.sh
```

## 停止

```bash
bash scripts/stop.sh
```

## 许可证

Apache License 2.0

## 致谢

基于 NebuSec/CyberMeowfia 安全研究。