"""
认证模块:负责生成/校验提权 token 与管理员口令。
- 提权 token 用于一次性绑定 CVE-2026-43501 漏洞利用会话。
- 管理员口令用于 Web 登录,首次启动时随机生成并打印到 stdout。
"""
import hmac
import os
import secrets
import time
from typing import Optional, Tuple

from Crypto.Hash import HMAC, SHA256

from config import (
    ADMIN_PASS,
    TOKEN_BYTES,
    TOKEN_FILE,
    TOKEN_TTL_SECONDS,
    NONCE_BYTES,
)


# ------------------------------------------------------------------ Token 工具
def generate_escalation_token() -> Tuple[str, str]:
    """
    生成 (token, nonce) 对。
    token: 用于 URL 路径 /escalate/<token>
    nonce: HMAC 校验,防止 token 被篡改
    """
    token = secrets.token_urlsafe(TOKEN_BYTES)
    nonce = secrets.token_urlsafe(NONCE_BYTES)
    return token, nonce


def sign_token(token: str, nonce: str) -> str:
    """用服务密钥对 token+nonce 做 HMAC-SHA256,生成签名"""
    secret = _load_or_create_secret()
    mac = HMAC.new(secret, f"{token}:{nonce}".encode(), digestmod=SHA256)
    return mac.hexdigest()


def verify_token(token: str, nonce: str, signature: str) -> bool:
    """校验 token 签名"""
    expected = sign_token(token, nonce)
    return hmac.compare_digest(expected, signature)


# ------------------------------------------------------------------ 管理员口令
def get_or_create_admin_pass() -> str:
    """第一次启动时生成 12 位随机口令,之后固定"""
    if ADMIN_PASS:
        return ADMIN_PASS
    if TOKEN_FILE.exists():
        data = TOKEN_FILE.read_text().strip().splitlines()
        # 第一行约定为 admin pass
        if data and data[0].startswith("ADMIN="):
            return data[0].split("=", 1)[1]
    pwd = secrets.token_urlsafe(9)  # 12 字符左右
    # 写入文件
    existing = ""
    if TOKEN_FILE.exists():
        existing = TOKEN_FILE.read_text()
    lines = existing.splitlines()
    new_lines = [f"ADMIN={pwd}"]
    for ln in lines:
        if not ln.startswith("ADMIN="):
            new_lines.append(ln)
    TOKEN_FILE.write_text("\n".join(new_lines) + "\n")
    return pwd


def write_escalation_token(token: str, nonce: str, signature: str,
                           expire_at: float) -> None:
    """持久化提权 token 以便崩溃恢复"""
    lines = []
    if TOKEN_FILE.exists():
        lines = [ln for ln in TOKEN_FILE.read_text().splitlines()
                 if not ln.startswith("ESC_")]
    lines.append(f"ESC_TOKEN={token}")
    lines.append(f"ESC_NONCE={nonce}")
    lines.append(f"ESC_SIG={signature}")
    lines.append(f"ESC_EXPIRE={int(expire_at)}")
    lines.append(f"ESC_ISSUED={int(time.time())}")
    TOKEN_FILE.write_text("\n".join(lines) + "\n")


def read_escalation_token() -> Optional[dict]:
    """读取持久化的提权 token"""
    if not TOKEN_FILE.exists():
        return None
    info = {}
    for ln in TOKEN_FILE.read_text().splitlines():
        if "=" in ln and ln.startswith("ESC_"):
            k, v = ln.split("=", 1)
            info[k] = v
    if not all(k in info for k in ("ESC_TOKEN", "ESC_NONCE", "ESC_SIG", "ESC_EXPIRE")):
        return None
    info["ESC_EXPIRE"] = int(info["ESC_EXPIRE"])
    return info


def invalidate_escalation_token() -> None:
    """提权完成后清除 token"""
    if not TOKEN_FILE.exists():
        return
    lines = [ln for ln in TOKEN_FILE.read_text().splitlines()
             if not ln.startswith("ESC_")]
    TOKEN_FILE.write_text("\n".join(lines) + ("\n" if lines else ""))


# ------------------------------------------------------------------ 内部
def _load_or_create_secret() -> bytes:
    """服务器启动时生成/加载 HMAC 密钥"""
    if TOKEN_FILE.exists():
        for ln in TOKEN_FILE.read_text().splitlines():
            if ln.startswith("SECRET="):
                return bytes.fromhex(ln.split("=", 1)[1])
    secret = secrets.token_bytes(32)
    lines = []
    if TOKEN_FILE.exists():
        lines = TOKEN_FILE.read_text().splitlines()
    lines.append(f"SECRET={secret.hex()}")
    TOKEN_FILE.write_text("\n".join(lines) + "\n")
    return secret