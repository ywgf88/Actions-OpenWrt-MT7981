#!/bin/sh
# 仅供 ImageBuilder 快速试机镜像使用：让试机镜像的默认值与本仓库正式构建保持一致。
# 只改这三项（时区、LAN 地址、IPv4 单栈）；DTS / 内核 / 升级脚本都不受影响。
# 首次启动时由 /etc/init.d/boot 执行，执行完自动删除。

uci -q set system.@system[0].timezone='CST-8'
uci -q set system.@system[0].zonename='Asia/Shanghai'
uci -q set network.lan.ipaddr='192.168.6.1'

# IPv4 单栈：删掉 wan6，禁止 lan 建 IPv6 地址，关掉 DHCPv6/RA
uci -q delete network.wan6
uci -q set network.lan.ipv6='0'
uci -q set network.lan.dhcpv6='disabled'
uci -q set network.lan.ndp='disabled'
uci -q set dhcp.lan.dhcpv6='disabled'
uci -q set dhcp.lan.ndp='disabled'
uci -q set dhcp.lan.ra='disabled'

uci -q commit system
uci -q commit network
uci -q commit dhcp
