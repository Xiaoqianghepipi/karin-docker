FROM node:22-bookworm-slim

# Karin 文档建议 Node.js 22+，并优先使用 pnpm 9。
ENV PNPM_HOME=/pnpm
ENV PATH=${PNPM_HOME}:${PATH}
ENV EXTRA_FONT_DIR=/app/fonts

RUN corepack enable \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates \
	&& update-ca-certificates \
	&& if [ -f /etc/apt/sources.list ]; then \
		sed -i 's|http://deb.debian.org/debian|https://mirrors.tuna.tsinghua.edu.cn/debian|g; s|http://security.debian.org/debian-security|https://mirrors.tuna.tsinghua.edu.cn/debian-security|g' /etc/apt/sources.list; \
	fi \
	&& if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
		sed -i 's|http://deb.debian.org/debian|https://mirrors.tuna.tsinghua.edu.cn/debian|g; s|http://security.debian.org/debian-security|https://mirrors.tuna.tsinghua.edu.cn/debian-security|g' /etc/apt/sources.list.d/debian.sources; \
	fi \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		chromium \
		ffmpeg \
		fontconfig \
		fonts-noto-core \
		fonts-noto-cjk \
		fonts-noto-cjk-extra \
		fonts-noto-color-emoji \
		fonts-noto-mono \
		fonts-wqy-zenhei \
		fonts-wqy-microhei \
	&& fc-cache -f \
	&& rm -rf /var/lib/apt/lists/* \
	&& corepack prepare pnpm@9.15.9 --activate \
	&& npm install -g @karinjs/cli@latest

WORKDIR /app
RUN mkdir -p /app/fonts

# 运行时优先使用挂载到 /app 的 Karin 项目目录。
# 初始化完成后，将项目内的 @karinjs 和 plugins 指向 /app 下的挂载目录
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 CMD ["node", "-e", "const url='http://127.0.0.1:7777';const ac=new AbortController();const timer=setTimeout(()=>ac.abort(),4000);fetch(url,{signal:ac.signal}).then((res)=>res.text()).then((text)=>{clearTimeout(timer);let data;try{data=JSON.parse(text);}catch{process.exit(1);}if(data&&data.code===200){process.exit(0);}process.exit(1);}).catch(()=>process.exit(1));"]
CMD ["sh", "-lc", "set -e; if [ -f package.json ]; then exec pnpm app; fi; if [ ! -f /app/karin-project/package.json ]; then echo '[Karin] 初始化项目中...' && pnpm create karin -y; fi; if [ ! -f /app/karin-project/package.json ]; then echo '[Karin] 未找到 /app/karin-project/package.json'; exit 1; fi; if [ -d \"${EXTRA_FONT_DIR}\" ]; then fc-cache -f \"${EXTRA_FONT_DIR}\" >/dev/null 2>&1 || true; fi; for name in @karinjs plugins; do mount_dir=\"/app/$name\"; project_dir=\"/app/karin-project/$name\"; if [ -d \"$mount_dir\" ] && [ -z \"$(ls -A \"$mount_dir\" 2>/dev/null)\" ] && [ -d \"$project_dir\" ]; then for item in \"$project_dir\"/* \"$project_dir\"/.[!.]* \"$project_dir\"/..?*; do [ -e \"$item\" ] || continue; mv \"$item\" \"$mount_dir\"/; done; fi; if [ -d \"$project_dir\" ]; then rm -rf \"$project_dir\"; fi; ln -s \"$mount_dir\" \"$project_dir\"; done; if [ -f /app/.env ] && [ ! -L /app/karin-project/.env ]; then ln -s /app/.env /app/karin-project/.env; fi; cd /app/karin-project; exec pnpm app;"]
