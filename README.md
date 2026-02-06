# Plex Media Server for fnOS

Auto-build Plex Media Server packages for fnOS - Daily updates from official releases

## Download

从 [Releases](https://github.com/conversun/plex-fnos/releases) 下载最新的 `.fpk` 文件。

## Install

1. 根据你的设备架构下载对应的 `.fpk` 文件
2. 在 fnOS 应用管理中选择「手动安装」
3. 上传 fpk 文件完成安装

## Web UI

安装后访问 `http://<your-nas-ip>:32400/web`

## Auto Update

GitHub Actions 每天自动检查 [Plex 官方下载](https://www.plex.tv/media-server-downloads/)，有新版本时自动构建并发布。

## Open Source

本项目完全开源，仅从官方渠道下载原版软件并重新打包，**无任何后门或修改**。构建脚本和 CI 流程公开透明，欢迎审查。

## Local Build

```bash
# 自动检测架构，构建最新版本
./update_plex.sh

# 指定架构
./update_plex.sh --arch arm
./update_plex.sh --arch x86

# 指定版本
./update_plex.sh --arch arm 1.42.2.10156

# 查看帮助
./update_plex.sh --help
```

## Version Tags

Release 版本号规则：
- `v1.42.2.10156` - 首次发布
- `v1.42.2.10156-r2` - 同版本的打包修订（上游未更新时重新发布）

## Credits

- [Plex](https://www.plex.tv/) - Media Server
