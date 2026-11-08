#!/bin/bash
#
# RAX3000M / 360T7 定制版 diy-part1.sh
# 作用：在更新 feeds 之前，引入 PassWall2 依赖与 Vantage 主题
# 执行目录：OpenWrt 源码根目录
#
set -e

# 1. 加入 PassWall2 依赖包源码（官方 OpenWrt packages feed 里没有 xray-core / chinadns-ng 等）
#    注意：PassWall 项目已迁移到 Openwrt-Passwall 组织，xiaorouji/* 旧地址返回 Repository not found
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' >>feeds.conf.default
# 2. 加入 PassWall2 LuCI 插件源码
echo 'src-git passwall2 https://github.com/Openwrt-Passwall/openwrt-passwall2.git;main' >>feeds.conf.default
# 3. 引入 Vantage 主题（LuCI 官方源没有这个主题，单独拉源码）
rm -rf /tmp/vantage-src
git clone --depth 1 https://github.com/anothaDev/luci-theme-vantage.git /tmp/vantage-src
rm -rf package/luci-theme-vantage package/luci-app-vantage
cp -rf /tmp/vantage-src/luci-theme-vantage package/
cp -rf /tmp/vantage-src/luci-app-vantage package/
# 4. 打印 feeds 列表，方便日志核对
cat feeds.conf.default
