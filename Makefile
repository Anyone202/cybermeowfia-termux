# CyberMeowfia Termux 顶层 Makefile
# 用法:
#   make help         - 查看帮助
#   make install      - 安装 Python 依赖
#   make run          - 在前台启动服务(方便调试)
#   make test         - 跑冒烟测试
#   make build-exploit - 编译 CVE-2026-43501 exploit 二进制
#   make clean        - 清理 __pycache__/logs

SHELL := /bin/bash
CMF_HOME := $(shell pwd)
PYTHON ?= python3

.PHONY: help install run test build-exploit clean

help:
	@echo "CyberMeowfia Termux Root Manager"
	@echo ""
	@echo "Targets:"
	@echo "  install        pip install -r requirements.txt"
	@echo "  run            python3 server.py  (前台)"
	@echo "  test           跑端到端冒烟测试"
	@echo "  build-exploit  编译 CVE-2026-43501 exploit"
	@echo "  clean          删除 __pycache__ / logs"
	@echo "  deps-termux    Termux 一键安装(pkg + pip)"

install:
	$(PYTHON) -m pip install --break-system-packages -r requirements.txt || \
	$(PYTHON) -m pip install -r requirements.txt

run:
	$(PYTHON) server.py

test:
	@bash scripts/test.sh

build-exploit:
	$(PYTHON) -c "import sys; sys.path.insert(0, '.'); from exploit_runner import ExploitRunner; \
		import os; os.chdir('exploits/CVE-2026-43501'); \
		print(ExploitRunner.ensure_binary(force_rebuild=True))"

clean:
	rm -rf __pycache__ */__pycache__ */*/__pycache__
	rm -rf logs/*
	@echo "[+] cleaned"