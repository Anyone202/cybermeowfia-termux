#!/data/data/com.termux/files/usr/bin/bash
# 停止 CyberMeowfia Termux 服务
set -e
CMF_HOME="${CMF_HOME:-$(cd "$(dirname "$0")/.." && pwd)}"
PID_FILE="$CMF_HOME/logs/server.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "[!] 未运行"
  exit 0
fi
PID=$(cat "$PID_FILE")
if kill -0 "$PID" 2>/dev/null; then
  echo "[*] 停止 PID=$PID ..."
  kill "$PID" || true
  sleep 1
  kill -9 "$PID" 2>/dev/null || true
fi
rm -f "$PID_FILE"
echo "[+] 已停止"

# 关闭通知
if command -v termux-notification-remove >/dev/null 2>&1; then
  termux-notification-remove 8787 2>/dev/null || true
fi

# 解除 wake-lock
termux-wake-unlock 2>/dev/null || true