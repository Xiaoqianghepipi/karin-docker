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
# 启动逻辑放在 start-karin.sh 中
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 CMD ["sh", "/app/health-check-karin.sh"]
CMD ["sh", "/app/start-karin.sh"]
