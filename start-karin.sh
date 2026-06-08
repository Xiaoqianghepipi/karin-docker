#!/bin/sh
set -e

# Karin 项目应在镜像构建阶段完成初始化，这里只做存在性校验。
if [ ! -f /app/karin-project/package.json ]; then
  echo '[Karin] 未找到 /app/karin-project/package.json，请重新构建镜像'
  exit 1
fi

# 刷新额外挂载的字体目录缓存，减少中文和特殊字符渲染成方块的概率。
if [ -d "${EXTRA_FONT_DIR}" ]; then
  fc-cache -f "${EXTRA_FONT_DIR}" >/dev/null 2>&1 || true
fi

mkdir -p /app/karin-data

# 先在启动时重建项目侧的三个链接，确保它们都指向 /app/karin-data。
rm -rf /app/karin-project/@karinjs /app/karin-project/plugins /app/karin-project/.env
ln -s /app/karin-data/@karinjs /app/karin-project/@karinjs
ln -s /app/karin-data/plugins /app/karin-project/plugins
ln -s /app/karin-data/.env /app/karin-project/.env

# 链接完成后，如果目录为空，再应用模板（模板只包含 @karinjs、plugins、.env）。
if [ -d /app/karin-template/@karinjs ] && { [ ! -d /app/karin-data/@karinjs ] || [ -z "$(ls -A /app/karin-data/@karinjs 2>/dev/null)" ]; }; then
  mkdir -p /app/karin-data/@karinjs
  cp -a /app/karin-template/@karinjs/. /app/karin-data/@karinjs/
fi

if [ -d /app/karin-template/plugins ] && { [ ! -d /app/karin-data/plugins ] || [ -z "$(ls -A /app/karin-data/plugins 2>/dev/null)" ]; }; then
  mkdir -p /app/karin-data/plugins
  cp -a /app/karin-template/plugins/. /app/karin-data/plugins/
fi

if [ -d /app/karin-data/.env ]; then
  echo '[Karin] /app/karin-data/.env 必须是文件，不能是目录'
  exit 1
fi

if [ ! -f /app/karin-data/.env ] && [ -f /app/karin-template/.env ]; then
  cp /app/karin-template/.env /app/karin-data/.env
fi

# 切换到真实项目目录并启动 Karin。
cd /app/karin-project
# 导出默认 Node 内存限制（可被外部覆盖）
export NODE_OPTIONS=${NODE_OPTIONS:-"--max-old-space-size=1536"}

# 直接启动；若启动失败则尝试强制修复环境（安装依赖并初始化），然后重试
pnpm app || (echo '[Karin] 启动失败，尝试强制修复环境...' && pnpm install -f || true && npx karin init || true && exec pnpm app)
