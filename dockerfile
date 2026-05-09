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
RUN mkdir -p /app/fonts \
	&& pnpm create karin -y \
	&& test -f /app/karin-project/package.json \
	&& rm -rf /app/karin-project/@karinjs /app/karin-project/plugins \
	&& ln -s /app/@karinjs /app/karin-project/@karinjs \
	&& ln -s /app/plugins /app/karin-project/plugins \
	&& mv /app/karin-project/.env /app/.env \
	&& ln -s /app/.env /app/karin-project/.env
COPY start-karin.sh /app/start-karin.sh
COPY health-check-karin.sh /app/health-check-karin.sh
RUN chmod +x /app/start-karin.sh /app/health-check-karin.sh

# Karin 环境在构建时完成初始化，运行时仅执行启动脚本。
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 CMD ["sh", "/app/health-check-karin.sh"]
CMD ["sh", "/app/start-karin.sh"]
