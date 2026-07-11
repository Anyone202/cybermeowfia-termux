"""
CyberMeowfia-Termux 全局配置
所有可调参数集中在此,便于在不同设备上适配。
"""
import os
import socket
from pathlib import Path

# ---------- 路径 ----------
PROJECT_ROOT = Path(__file__).resolve().parent
EXPLOIT_DIR = PROJECT_ROOT / "exploits" / "CVE-2026-43501"
EXPLOIT_BIN = EXPLOIT_DIR / "exploit"
EXPLOIT_SRC = EXPLOIT_DIR / "exploit.c"
LOG_DIR = PROJECT_ROOT / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)
TOKEN_FILE = LOG_DIR / "session.token"

# ---------- 网络 ----------
BIND_HOST = "127.0.0.1"          # 仅本机回环,符合需求
BIND_PORT = 8787                 # 避开常用端口
PUBLIC_BASE_URL = f"http://{BIND_HOST}:{BIND_PORT}"

# ---------- 提权链接 ----------
TOKEN_BYTES = 32                 # 256-bit 随机 token
TOKEN_TTL_SECONDS = 900          # 提权链接 15 分钟过期
NONCE_BYTES = 16

# ---------- Web 鉴权 ----------
# 服务端在第一次访问 /login 时生成一个口令并写入 TOKEN_FILE
# 也可手动 export CMF_ADMIN_PASS=... 覆盖
ADMIN_PASS = os.environ.get("CMF_ADMIN_PASS") or None

# ---------- Root 管理白名单 ----------
# 文件系统访问的根路径白名单,防止越权访问
FS_ALLOWED_ROOTS = [
    "/sdcard",
    "/data/adb/modules",
    "/data/adb/magisk",
    "/data/local/tmp",
    "/system",
    "/vendor",
    "/proc/1",
    "/proc/self",
]

# 禁止访问的敏感路径(优先级最高)
FS_DENY_PATHS = [
    "/data/data",        # 用户应用数据(隐私)
    "/data/user/0",      # 同上
    "/proc/kallsyms",    # 内核符号(已禁用 kptr_restrict)
    "/proc/kcore",
    "/sys/firmware",
]

# 进程管理白名单:可结束的进程
PROCESS_KILL_ALLOW = True  # 是否允许 kill

# ---------- 提权漏洞 ----------
EXPLOIT_TIMEOUT_SECONDS = 90    # 内核漏洞利用最长执行时间
EXPLOIT_RETRY = 1               # 失败重试次数

# ---------- 通知 ----------
NOTIFY_TITLE = "CyberMeowfia Termux"
NOTIFY_TICKER = "Root Manager 持续运行中"

# ---------- 调试 ----------
DEBUG = os.environ.get("CMF_DEBUG") == "1"


def is_termux() -> bool:
    """检测是否运行在 Termux 环境中"""
    return os.environ.get("PREFIX", "").endswith("com.termux") or \
           os.path.exists("/data/data/com.termux/files/usr/bin/pkg")