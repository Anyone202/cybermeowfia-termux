#!/data/data/com.termux/files/usr/bin/bash
# ------------------------------------------------------------------
# CyberMeowfia Termux 一键安装脚本
# 在 Termux 中执行:bash install.sh
# ------------------------------------------------------------------
set -e

CMF_HOME="${CMF_HOME:-$(cd "$(dirname "$0")/.." && pwd)}"
REPO_URL="${REPO_URL:-}"

echo "==================================================="
echo " CyberMeowfia Termux · 安装"
echo " 安装目录:$CMF_HOME"
echo "==================================================="

# 1. 必要工具链
echo "[1/5] 安装 Termux 工具链 ..."
pkg update -y
pkg install -y python git wget ndk-sysroot clang make libffi openssl

# 2. Python 依赖
echo "[2/5] 安装 Python 依赖 ..."
# Termux 中 pip 不能直接升级自己，需要先安装 python-pip 包
pkg install -y python-pip 2>/dev/null || true
# 优先用 pkg 安装（Termux 官方包），pip 作补充（--break-system-packages 绕过外部管理限制）
pkg install -y python-flask python-requests 2>/dev/null || true
pip install --break-system-packages pycryptodome werkzeug 2>/dev/null || true
pip install --break-system-packages -r "$CMF_HOME/requirements.txt" 2>/dev/null || true

# 3. Termux:API (用于通知栏)
echo "[3/5] 检查 Termux:API ..."
if ! command -v termux-notification >/dev/null 2>&1; then
  echo "  请从 F-Droid 安装 Termux:API 应用:"
  echo "  https://f-droid.org/packages/com.termux.api/"
  echo "  安装后授予通知权限,本工具会使用 termux-notification 在通知栏保持运行提示"
else
  echo "  termux-notification 已就绪"
fi

# 4. 编译漏洞利用二进制
echo "[4/5] 预编译 CVE-2026-43501 exploit (首次较慢,需下载 XDK + target_db) ..."
cd "$CMF_HOME"
python3 -c "
import sys; sys.path.insert(0, '.')
from exploit_runner import ExploitRunner
try:
    p = ExploitRunner.ensure_binary(force_rebuild=False)
    print('[+] exploit 二进制:', p)
except Exception as e:
    print('[!] 预编译失败(可后续手动编译):', e)
" || true

# 5. 设置启动脚本可执行
echo "[5/5] 设置可执行权限 ..."
chmod +x "$CMF_HOME/scripts/"*.sh 2>/dev/null || true

echo
echo "==================================================="
echo " 安装完成"
echo " 启动:bash $CMF_HOME/scripts/start.sh"
echo " 停止:bash $CMF_HOME/scripts/stop.sh"
echo "==================================================="