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

# 校验构建阶段建立的关键链接仍然存在。
if [ ! -L /app/karin-project/@karinjs ] || [ ! -L /app/karin-project/plugins ]; then
  echo '[Karin] 关键目录链接缺失，请检查挂载配置或重建镜像'
  exit 1
fi

# 切换到真实项目目录并启动 Karin。
cd /app/karin-project
exec pnpm app
