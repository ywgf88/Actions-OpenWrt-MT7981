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
# 3. 默认局域网地址改 192.168.6.1（config_generate 里 lan 的默认 ipad 是 192.168.1.1）
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate
# 4. IPv4 单栈：让首次生成配置时完全不创建 IPv6 地址段与 wan6
#    （config_generate 里所有 IPv6 初始化都用 /proc/sys/net/ipv6 做判断，屏蔽掉即可）
sed -i 's|\[ -e /proc/sys/net/ipv6 \]|[ -e /proc/sys/net/ipv6-disabled ]|g' package/base-files/files/bin/config_generate

# 5. CT3003 改成 ubootmod（FIT / .itb）布局
#    目的：用户机器已刷只认 itb 的新 uboot，产物要与 rax3000m / 360t7 一样是 sysupgrade.itb
#    做法照 ImmortalWrt 的 cetron_ct3003-ubootmod：新增 ubootmod 专用 DTS（ubi 铺满 flash、内核放 fit 卷），
#    并在 filogic.mk 里加一个独立的设备定义（原 stock 定义保持不动，互不影响）
BASE="$(cd "$(dirname "$0")" && pwd)"
DTS_DIR=target/linux/mediatek/dts
MK=target/linux/mediatek/image/filogic.mk

cp "$BASE/dts/mt7981b-cetron-ct3003.dtsi" "$DTS_DIR/"
cp "$BASE/dts/mt7981b-cetron-ct3003-ubootmod.dts" "$DTS_DIR/"

if ! grep -q 'mt7981b-cetron-ct3003-ubootmod' "$MK"; then
  awk -v body="$BASE/dts/ct3003-ubootmod-body.mk" '
    /^define Device\/cetron_ct3003$/ {
      inblk = 1
      print "define Device/cetron_ct3003"
      while ((getline l < body) > 0) print l
      close(body)
      next
    }
    inblk && $0 == "endef" { inblk = 0; print "endef"; next }
    inblk { next }
    { print }
    END { if (inblk) exit 4 }
  ' "$MK" > "$MK.new" && mv "$MK.new" "$MK"
fi

grep -q 'mt7981b-cetron-ct3003-ubootmod' "$MK" || { echo "ERROR: filogic.mk 未切换到 ubootmod 定义"; exit 1; }
grep -q 'IMAGES := sysupgrade.itb' "$MK" || { echo "ERROR: ITB 规则未写入"; exit 1; }
echo "CT3003 已切换为 ubootmod/FIT(itb) 定义（设备名保持 cetron_ct3003）"

echo "diy-part2 done."
