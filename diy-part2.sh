#!/bin/bash
#
# RAX3000M / 360T7 定制版 diy-part2.sh
# 作用：在 feeds 安装完成之后，修改源码默认值（主题、时区、IPv4 单栈）
# 执行目录：OpenWrt 源码根目录
#
# 1. 默认主题改为 Vantage（LuCI 集合包默认依赖 bootstrap，替换成 vantage）
find feeds/luci/collections -name Makefile -exec sed -i 's/luci-theme-bootstrap/luci-theme-vantage/g' {} \;
# 2. 时区改为中国标准时间（默认 GMT0，不装 zonename 会显示 UTC）
sed -i "s/timezone='GMT0'/timezone='CST-8'/" package/base-files/files/bin/config_generate
# 3. 默认局域网地址保持 192.168.1.1；如需改成别的，取消下面这行注释并改数字
#sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate
# 4. IPv4 单栈：让首次生成配置时完全不创建 IPv6 地址段与 wan6
#    （config_generate 里所有 IPv6 初始化都用 /proc/sys/net/ipv6 做判断，屏蔽掉即可）
sed -i 's|\[ -e /proc/sys/net/ipv6 \]|[ -e /proc/sys/net/ipv6-disabled ]|g' package/base-files/files/bin/config_generate
echo "diy-part2 done."
