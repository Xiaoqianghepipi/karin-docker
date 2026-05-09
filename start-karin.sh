#!/bin/sh
set -e

# 如果当前目录本身就是 Karin 项目，直接启动。
if [ -f package.json ]; then
  exec pnpm app
fi

# 如果目标项目还不存在，就先静默初始化一个标准 Karin 项目。
if [ ! -f /app/karin-project/package.json ]; then
  echo '[Karin] 初始化项目中...'
  pnpm create karin -y
fi

# 初始化后再次确认项目文件是否已经生成，避免后续误启动。
if [ ! -f /app/karin-project/package.json ]; then
  echo '[Karin] 未找到 /app/karin-project/package.json'
  exit 1
fi

# 刷新额外挂载的字体目录缓存，减少中文和特殊字符渲染成方块的概率。
if [ -d "${EXTRA_FONT_DIR}" ]; then
  fc-cache -f "${EXTRA_FONT_DIR}" >/dev/null 2>&1 || true
fi

# 将宿主机挂载目录接回项目目录，并在必要时把项目内已有内容搬过去。
for name in @karinjs plugins; do
  mount_dir="/app/$name"
  project_dir="/app/karin-project/$name"

  # 挂载目录为空时，先把项目内原有文件移动过去，再删掉项目内旧目录。
  if [ -d "$mount_dir" ] && [ -z "$(ls -A "$mount_dir" 2>/dev/null)" ] && [ -d "$project_dir" ]; then
    for item in "$project_dir"/* "$project_dir"/.[!.]* "$project_dir"/..?*; do
      [ -e "$item" ] || continue
      mv "$item" "$mount_dir"/
    done
  fi

  # 无论挂载目录是否为空，都让项目内路径指向挂载目录。
  if [ -d "$project_dir" ]; then
    rm -rf "$project_dir"
  fi

  ln -s "$mount_dir" "$project_dir"
done

# .env 优先使用容器外部挂载的版本；如果外部不存在，就把项目里的初始版本同步出来。
if [ -f /app/.env ]; then
  rm -f /app/karin-project/.env
  ln -s /app/.env /app/karin-project/.env
elif [ -f /app/karin-project/.env ]; then
  cp /app/karin-project/.env /app/.env
fi

# 切换到真实项目目录并启动 Karin。
cd /app/karin-project
exec pnpm app
