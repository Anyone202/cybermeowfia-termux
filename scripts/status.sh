#!/data/data/com.termux/files/usr/bin/bash
# 查看 CyberMeowfia Termux 服务状态
set -e
CMF_HOME="${CMF_HOME:-$(cd "$(dirname "$0")/.." && pwd)}"
PID_FILE="$CMF_HOME/logs/server.pid"
PORT="${CMF_PORT:-8787}"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  PID=$(cat "$PID_FILE")
  echo "[+] 运行中,PID=$PID"
  echo "    健康检查:$(curl -s http://127.0.0.1:${PORT}/healthz)"
else
  echo "[-] 未运行"
fi