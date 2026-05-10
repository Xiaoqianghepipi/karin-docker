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

# 如果宿主机把 /app/karin-data 挂载进来且为空，使用镜像内的模板填充它。
if [ -d /app/karin-data ] && [ -z "$(ls -A /app/karin-data 2>/dev/null)" ]; then
  if [ -d /opt/karin-template ]; then
    echo '[Karin] 填充 karim 数据目录 /app/karin-data from template'
    cp -a /opt/karin-template/. /app/karin-data/
  fi
fi

# 校验构建阶段建立的关键链接仍然存在。
if [ ! -L /app/karin-project/@karinjs ] || [ ! -L /app/karin-project/plugins ]; then
  echo '[Karin] 关键目录链接缺失，请检查挂载配置或重建镜像'
  exit 1
fi

# 切换到真实项目目录并启动 Karin。
cd /app/karin-project
# 直接启动；若启动失败则尝试强制修复环境（安装依赖并初始化），然后重试
pnpm app || (echo '[Karin] 启动失败，尝试强制修复环境...' && pnpm install -f || true && npx karin init || true && exec pnpm app)
