#!/data/data/com.termux/files/usr/bin/bash
# CyberMeowfia Termux 冒烟测试
# 在后台启动服务,跑完所有 API 后清理
set -e
CMF_HOME="$(cd "$(dirname "$0")/.." && pwd)"
cd "$CMF_HOME"

cleanup() {
  if [ -n "${SERVER_PID:-}" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# 1. 启动
rm -f logs/session.token
python3 server.py > /tmp/cmf-test.log 2>&1 &
SERVER_PID=$!
sleep 2.5

PASS=$(grep -E '^ADMIN=' logs/session.token | cut -d= -f2-)
[ -n "$PASS" ] || { echo "[!] 未生成口令"; exit 1; }
echo "[+] admin pass: $PASS"

curl -s -c /tmp/cmf-test-c -o /dev/null -X POST -d "password=$PASS" \
  http://127.0.0.1:8787/login

# 2. 基础 API
test_api() {
  local desc="$1" url="$2" expect="$3" extra="$4"
  local body
  if [ -n "$extra" ]; then
    body=$(curl -s -b /tmp/cmf-test-c $extra "$url")
  else
    body=$(curl -s -b /tmp/cmf-test-c "$url")
  fi
  if echo "$body" | grep -q "$expect"; then
    echo "  [PASS] $desc"
  else
    echo "  [FAIL] $desc -> $body"
    exit 1
  fi
}

echo "[*] 跑核心 API ..."
test_api "GET /healthz"             "http://127.0.0.1:8787/healthz"        '"ok":true'
test_api "GET /api/root/status"     "http://127.0.0.1:8787/api/root/status" '"is_root"'
test_api "GET /api/device"          "http://127.0.0.1:8787/api/device"     '"uname"'
test_api "GET /api/processes"       "http://127.0.0.1:8787/api/processes"  '"count"'
test_api "GET /api/magisk/status"   "http://127.0.0.1:8787/api/magisk/status" '"source"'
test_api "GET /api/magisk/modules"  "http://127.0.0.1:8787/api/magisk/modules" '"ok"'

# 3. 提权链接
echo "[*] 提权链接生成 + 落地页 ..."
LJ=$(curl -s -b /tmp/cmf-test-c -X POST http://127.0.0.1:8787/api/escalate/link)
URL=$(echo "$LJ" | python3 -c "import sys,json; print(json.load(sys.stdin)['link']['url'])")
[ -n "$URL" ] || { echo "[!] 未生成链接"; exit 1; }

HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
[ "$HTTP" = "200" ] && echo "  [PASS] 落地页 200" || { echo "  [FAIL] 落地页 $HTTP"; exit 1; }

# 错误签名应 403
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "${URL%%\?*}/escalate/dummy?n=x&s=y")
[ "$HTTP" = "403" ] || [ "$HTTP" = "404" ] && echo "  [PASS] 错误签名/无效 token 拒绝" || \
  echo "  [WARN] 错误签名返回 $HTTP"

# 4. 白名单
echo "[*] 路径白名单 ..."
RESP=$(curl -s -b /tmp/cmf-test-c "http://127.0.0.1:8787/api/fs/list?path=/data/data")
echo "$RESP" | grep -q "黑名单" && echo "  [PASS] 黑名单路径拒绝" || { echo "  [FAIL]"; exit 1; }

# 5. 越权命令注入 (mode / owner 字段)
echo "[*] 命令注入防御 ..."
RESP=$(curl -s -b /tmp/cmf-test-c -X POST -H "Content-Type: application/json" \
  -d '{"path":"/sdcard","mode":"755; rm -rf /"}' http://127.0.0.1:8787/api/fs/chmod)
echo "$RESP" | grep -q "非法 mode" && echo "  [PASS] chmod 拒绝非法 mode" || \
  { echo "[!] 危险 mode 未被拒绝:$RESP"; exit 1; }

echo
echo "[+] 所有冒烟测试通过"