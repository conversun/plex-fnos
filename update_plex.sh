#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"
WORK_DIR="/tmp/plex_update_$$"
PLEX_VERSION="${1:-latest}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

get_latest_version() {
    info "获取最新版本信息..."
    
    local api_response=$(curl -sL "https://plex.tv/api/downloads/5.json" 2>/dev/null)
    
    if [ "$PLEX_VERSION" = "latest" ]; then
        PLEX_VERSION=$(echo "$api_response" | grep -o '"version":"[^"]*"' | head -1 | sed 's/"version":"//;s/"//' | cut -d'-' -f1)
    fi
    
    [ -z "$PLEX_VERSION" ] && error "无法获取版本信息，请手动指定: $0 1.42.2.10156"
    
    info "目标版本: $PLEX_VERSION"
}

get_download_url() {
    local api_response=$(curl -sL "https://plex.tv/api/downloads/5.json" 2>/dev/null)
    
    # 查找 debian distro 且 build 为 linux-x86_64 的 URL
    DOWNLOAD_URL=$(echo "$api_response" | grep -o '"build":"linux-x86_64","distro":"debian","url":"[^"]*"' | head -1 | sed 's/.*"url":"//;s/"$//')
    
    [ -z "$DOWNLOAD_URL" ] && error "无法获取下载链接"
    info "下载链接: $DOWNLOAD_URL"
}

download_deb() {
    info "下载 Plex Media Server..."
    mkdir -p "$WORK_DIR"
    
    curl -L -f -o "$WORK_DIR/plex.deb" "$DOWNLOAD_URL" || error "下载失败"
    info "下载完成: $(du -h "$WORK_DIR/plex.deb" | cut -f1)"
}

extract_deb() {
    info "解压 deb 包..."
    cd "$WORK_DIR"
    ar -x plex.deb
    mkdir -p extracted
    tar -xf data.tar.xz -C extracted
    [ -d "extracted/usr/lib/plexmediaserver" ] || error "deb 包结构异常"
}

build_app_tgz() {
    info "构建 app.tgz..."
    
    local src="$WORK_DIR/extracted/usr/lib/plexmediaserver"
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/bin" "$dst/lib" "$dst/ui/images"
    
    cp -a "$src"/* "$dst/"
    cp "$PKG_DIR/bin/plex-server" "$dst/bin/"
    chmod +x "$dst/bin/plex-server"
    
    cp -a "$PKG_DIR/ui"/* "$dst/ui/"
    
    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

update_manifest() {
    info "更新 manifest..."
    local checksum=$(md5 -q "$WORK_DIR/app.tgz" 2>/dev/null || md5sum "$WORK_DIR/app.tgz" | cut -d' ' -f1)
    
    sed -i.tmp "s/^version.*=.*/version         = ${PLEX_VERSION}/" "$PKG_DIR/manifest"
    sed -i.tmp "s/^checksum.*=.*/checksum        = ${checksum}/" "$PKG_DIR/manifest"
    rm -f "$PKG_DIR/manifest.tmp"
}

build_fpk() {
    local fpk_name="plexmediaserver_${PLEX_VERSION}_amd64.fpk"
    info "打包 $fpk_name..."
    
    mkdir -p "$WORK_DIR/package"
    
    cp "$WORK_DIR/app.tgz" "$WORK_DIR/package/"
    cp -a "$PKG_DIR/cmd" "$WORK_DIR/package/"
    cp -a "$PKG_DIR/config" "$WORK_DIR/package/"
    cp -a "$PKG_DIR/wizard" "$WORK_DIR/package/"
    cp "$PKG_DIR"/*.sc "$WORK_DIR/package/" 2>/dev/null || true
    cp "$PKG_DIR"/ICON*.PNG "$WORK_DIR/package/"
    cp "$PKG_DIR/manifest" "$WORK_DIR/package/"
    
    cd "$WORK_DIR/package"
    tar -czf "$SCRIPT_DIR/$fpk_name" *
    
    info "生成: $SCRIPT_DIR/$fpk_name ($(du -h "$SCRIPT_DIR/$fpk_name" | cut -f1))"
}

show_help() {
    cat << EOF
用法: $0 [版本号|latest]

示例:
  $0                    # 最新稳定版
  $0 1.42.2.10156       # 指定版本
  $0 latest             # 最新版本
EOF
}

main() {
    [ "$1" = "-h" ] || [ "$1" = "--help" ] && { show_help; exit 0; }
    
    echo "========================================"
    echo "  Plex Media Server fnOS Package Builder"
    echo "========================================"
    echo
    
    for cmd in curl ar tar sed; do
        command -v $cmd &>/dev/null || error "缺少依赖: $cmd"
    done
    
    [ -f "$PKG_DIR/manifest" ] || error "找不到 fnos 目录"
    
    local current_version=$(grep "^version" "$PKG_DIR/manifest" | awk -F'=' '{print $2}' | tr -d ' ')
    info "当前版本: $current_version"
    
    get_latest_version
    get_download_url
    
    if [ "$current_version" = "$PLEX_VERSION" ]; then
        warn "已是最新版本"
        read -p "强制重新构建? [y/N] " -n 1 -r; echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
    
    download_deb
    extract_deb
    build_app_tgz
    update_manifest
    build_fpk
    
    echo
    info "完成: $current_version -> $PLEX_VERSION"
}

main "$@"
