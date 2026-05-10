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
	# 保存一份模板供运行时在挂载为空时填充
	&& rm -rf /opt/karin-template || true \
	&& cp -a /app/karin-project /opt/karin-template \
	# 准备统一的数据目录，优先使用 /app/karin-data（可被宿主挂载覆盖）
	&& mkdir -p /app/karin-data \
	&& cp -a /app/karin-project/. /app/karin-data/ \
	# 在项目中创建指向统一数据目录的链接
	&& rm -rf /app/karin-project/@karinjs /app/karin-project/plugins || true \
	&& ln -s /app/karin-data/@karinjs /app/karin-project/@karinjs \
	&& ln -s /app/karin-data/plugins /app/karin-project/plugins \
	# 将 .env 放到统一数据目录并链接回项目
	&& if [ -f /app/karin-project/.env ]; then mkdir -p /app/karin-data && mv /app/karin-project/.env /app/karin-data/.env; fi \
	&& ln -sf /app/karin-data/.env /app/karin-project/.env
COPY start-karin.sh /app/start-karin.sh
COPY health-check-karin.sh /app/health-check-karin.sh
RUN chmod +x /app/start-karin.sh /app/health-check-karin.sh

# Karin 环境在构建时完成初始化，运行时仅执行启动脚本。
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 CMD ["sh", "/app/health-check-karin.sh"]
CMD ["sh", "/app/start-karin.sh"]
