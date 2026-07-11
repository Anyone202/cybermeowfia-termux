#!/data/data/com.termux/files/usr/bin/bash
# ------------------------------------------------------------------
# CyberMeowfia Termux 启动脚本
# - 防止设备休眠 (termux-wake-lock)
# - 后台运行服务
# - 在通知栏显示持续运行提示
# - 写入 PID 文件,便于 stop.sh 终止
# ------------------------------------------------------------------
set -e

CMF_HOME="${CMF_HOME:-$(cd "$(dirname "$0")/.." && pwd)}"
PID_FILE="$CMF_HOME/logs/server.pid"
LOG_FILE="$CMF_HOME/logs/server.stdout.log"
PORT="${CMF_PORT:-8787}"
NOTIFY_ID=8787

cd "$CMF_HOME"

# 已启动?
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "[!] 服务已在运行,PID=$(cat "$PID_FILE")"
  exit 0
fi

# 防休眠
termux-wake-lock >/dev/null 2>&1 || true

# 启动
echo "[*] 启动 CyberMeowfia Termux Root Manager ..."
nohup python3 server.py >>"$LOG_FILE" 2>&1 &
SERVER_PID=$!
echo "$SERVER_PID" > "$PID_FILE"
sleep 1.5

# 健康检查
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "[!] 启动失败,查看日志:$LOG_FILE"
  exit 1
fi

# 通知栏
NOTIFY_TITLE="CyberMeowfia Termux"
NOTIFY_BODY="Root Manager 运行中 · http://127.0.0.1:${PORT} · PID ${SERVER_PID}"
if command -v termux-notification >/dev/null 2>&1; then
  termux-notification \
    --id "$NOTIFY_ID" \
    --title "$NOTIFY_TITLE" \
    --content "$NOTIFY_BODY" \
    --priority high \
    --ongoing \
    --action "termux-open http://127.0.0.1:${PORT}/login" \
    --button1 "打开管理界面" \
    --button1-action "termux-open http://127.0.0.1:${PORT}/login" >/dev/null 2>&1 || true
fi

# 输出口令(首次启动会生成)
PASSWORD=$(grep -E "^ADMIN=" "$CMF_HOME/logs/session.token" 2>/dev/null | head -1 | cut -d= -f2-)
if [ -n "$PASSWORD" ]; then
  echo
  echo "============================================================"
  echo " 管理员口令:$PASSWORD"
  echo " 登录地址:http://127.0.0.1:${PORT}/login"
  echo " 日志:$LOG_FILE"
  echo "============================================================"
fi

# 自动打开浏览器
if command -v termux-open >/dev/null 2>&1; then
  termux-open "http://127.0.0.1:${PORT}/login" >/dev/null 2>&1 || true
fi