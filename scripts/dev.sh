#!/bin/bash
# 本地开发：构建前端 + 运行 Rust 后端
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

# 安装前端依赖（如果缺失）
if [ ! -d "web/node_modules/@vue/tsconfig" ]; then
    echo "Installing frontend dependencies..."
    cd web && npm ci && cd ..
fi

# 检测前端源码是否比 dist 更新
NEED_BUILD=0
if [ ! -d "web/dist" ]; then
    NEED_BUILD=1
else
    # 找到 web/src 下最新修改的文件时间戳
    LATEST_SRC=$(find web/src -type f -newer web/dist -print -quit 2>/dev/null)
    # 同时检查 web 根目录的配置文件
    for f in web/index.html web/vite.config.ts web/tsconfig.json web/package.json; do
        if [ -f "$f" ] && [ "$f" -nt "web/dist" ]; then
            LATEST_SRC="$f"
            break
        fi
    done
    if [ -n "$LATEST_SRC" ]; then
        NEED_BUILD=1
    fi
fi

if [ "$NEED_BUILD" -eq 1 ]; then
    echo "Frontend changed, rebuilding..."
    cd web && npm run build && cd ..
else
    echo "Frontend up to date, skipping build."
fi

# 运行
cargo run "$@"
