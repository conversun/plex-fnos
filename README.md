# Plex Media Server for fnOS

Auto-build Plex Media Server packages for fnOS - Daily updates from official releases

## Download

从 [Releases](https://github.com/conversun/plex-fnos/releases) 下载最新的 `.fpk` 文件。

## Install

1. 下载 `plexmediaserver_x.x.x.xxxxx_amd64.fpk`
2. 在 fnOS 应用管理中选择「手动安装」
3. 上传 fpk 文件完成安装

## Web UI

安装后访问 `http://<your-nas-ip>:32400/web`

## Auto Update

GitHub Actions 每天自动检查 [Plex 官方下载](https://www.plex.tv/media-server-downloads/)，有新版本时自动构建并发布。

## Architecture

- **Platform**: fnOS (飞牛私有云)
- **Architecture**: x86_64 (amd64)

## Credits

- [Plex](https://www.plex.tv/) - Media Server
