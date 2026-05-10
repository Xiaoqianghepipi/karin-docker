# Karin Docker 镜像使用说明

本仓库通过 GitHub Actions 自动构建并发布镜像到 GHCR。

# 镜像地址

```bash
https://ghcr.io/xiaoqianghepipi/karin-docker
```

版本号：

- latest：默认分支最新构建（即最新 Karin-docker）
- x.x.x：按 Karin 版本固定

# 1. 拉取镜像

```bash
docker pull ghcr.io/xiaoqianghepipi/karin-docker:latest
```

# 2. docker部署

## 1.使用 Docker CLI 部署

Linux 示例：

```bash
docker run -d \
	--name karin \
	-p 7777:7777 \
	--restart unless-stopped \
	-v /opt/karin/data:/app/karin-data:rw \
	-v /home/karin/fonts:/app/fonts:ro \
	ghcr.io/xiaoqianghepipi/karin-docker:<版本号>
```

Windows PowerShell 示例：

```powershell
docker run -d `
	--name karin `
	-p 7777:7777 `
	-v D:/karin/data:/app/karin-data:rw `
	-v D:/karin/fonts:/app/fonts:ro `
	--restart unless-stopped `
	ghcr.io/xiaoqianghepipi/karin-docker:<版本号>
```

## 2. 使用 Docker Compose 部署（推荐）

创建 compose.yaml：

```yaml
services:
	karin:
		image: ghcr.io/xiaoqianghepipi/karin-docker:<版本号>
		container_name: karin
		ports:
			- "7777:7777"
		volumes:
            - /opt/karin/data:/app/karin-data:rw
			- /home/karin/fonts:/app/fonts:ro
		restart: unless-stopped
```

说明：

- 容器监听 7777 端口
- 请务必挂载 /app/karin-data 用于持久化数据
- fonts 目录用于挂载额外的字体文件（可选）

启动：

```bash
docker compose up -d
```

查看日志：

```bash
docker compose logs -f karin
```

# 3. 更新镜像

Docker Compose 方式：

```bash
docker compose pull
docker compose up -d
```

# 4. 自动构建与自动更新说明

本仓库已配置两个工作流：

- .github/workflows/docker-build.yml：负责构建并推送 GHCR 镜像
- .github/workflows/karin-update-check.yml：定时检查 GitHub releases 上 Karin core 是否更新
- 当检测到新版本时，会自动更新 .github/karin-core-version.txt 并提交
- 该提交会触发 docker-build.yml 自动构建新镜像

# 5. 常见问题

启动后访问不到服务：

- 检查 7777 端口是否映射
- 检查服务器安全组/防火墙是否放行 7777
- 用 docker logs karin 查看容器日志

# 6. 原项目链接

- Karin 官方仓库：
 https://github.com/KarinJS/Karin

- Karin 官方文档：
 https://karinjs.com/