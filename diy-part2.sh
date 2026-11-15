#!/bin/bash
#
# RAX3000M / 360T7 / CT3003 定制版 diy-part2.sh
# 作用：在 feeds 安装完成之后，修改源码默认值（主题、时区、IPv4 单栈）
#       以及 CT3003 的 ubootmod/FIT 设备定义与升级路径
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
#    注意：这里刻意不生成 factory.bin。上游 cetron_ct3003 的 factory.bin 带 cetron-header(rd30) 头，
#    是给「原厂 U-Boot + stock 布局」刷入用的；本设备的 FIT + 128M ubi("fit") 布局与之不兼容，
#    把 sysupgrade.itb 包上 cetron 头虽然能通过 OEM 的头校验，但刷进去起不来，属危险产物。
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

# 6. CT3003 升级路径修正
#    现象：在运行系统里 sysupgrade，新镜像写进去了，重启后版本却没变。
#    原因：本布局的 U-Boot（ubi_read_production=ubi read $loadaddr fit）和内核
#          （root=/dev/fit0）都只按卷名 "fit" 取镜像；而 nand.sh 第 7 行是
#          CI_KERNPART="${CI_KERNPART:-kernel}"，只有走 fit_do_upgrade 的设备才会
#          把真实卷名交上去。上游 platform.sh 的设备列表里没有
#          cetron,ct3003-ubootmod（这是我们自己加的），于是掉进末尾默认分支，
#          整个 FIT 被写进名为 kernel 的卷，引导根本不读它。
#          （上游的 cmcc,rax3000m、qihoo,360t7、qihoo,360t7-ubi 本来就在
#            fit_do_upgrade 那组里，所以它们从来没有这个毛病。）
#    做法：不复制任何升级逻辑，只把本设备并入上游那组 FIT 设备：
#          在 platform_do_upgrade 的 case 里加一条
#              cetron,ct3003-ubootmod)  fit_do_upgrade "$1"  ;;
#          上游 fit_do_upgrade（fitblk 包的 /lib/upgrade/fit.sh）自己会：
#            ① 读设备树 chosen/rootdisk 指向的 UBI 卷，把 volname（本设备为 fit）
#               导出成 CI_KERNPART —— 这两项在我们自己那份 DTS 里已经写好；
#            ② 先 fitblk /dev/fit0 释放块设备，再删卷（解决 Resource busy）；
#            ③ 删 fit 与 rootfs_data，按镜像实际长度重建 fit，剩余空间全给
#              rootfs_data，写入 FIT，恢复配置并重启。
#          镜像里已装 fitblk 包（/usr/sbin/fitblk + /lib/upgrade/fit.sh），
#          platform.sh 的 RAMFS_COPY_BIN 也带了 fitblk，无需额外改动。
UPG=target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh
if [ -f "$UPG" ] && ! grep -q 'cetron,ct3003-ubootmod)' "$UPG"; then
  awk '
    /^platform_do_upgrade\(\) \{/ { in_func = 1 }
    in_func && !done && /^[[:blank:]]*case "\$board" in/ {
      print
      print "\tcetron,ct3003-ubootmod)"
      print "\t\tfit_do_upgrade \"$1\""
      print "\t\t;;"
      done = 1
      next
    }
    { print }
    END { if (!done) { print "ERROR: platform.sh 结构不符，未找到 case \"$board\" in" > "/dev/stderr"; exit 4 } }
  ' "$UPG" > "$UPG.new" && mv "$UPG.new" "$UPG" || exit 1
fi

grep -q 'cetron,ct3003-ubootmod)' "$UPG" || { echo "ERROR: platform.sh 改造失败（缺少 cetron 分支）"; exit 1; }
grep -A1 'cetron,ct3003-ubootmod)' "$UPG" | grep -q 'fit_do_upgrade' || { echo "ERROR: cetron 分支未指向 fit_do_upgrade"; exit 1; }
bash -n "$UPG" || { echo "ERROR: platform.sh 语法检查失败"; exit 1; }
echo "CT3003 升级路径已修正：并入上游 fit_do_upgrade 分支（自动取 fit 卷名并释放 fitblk）"

echo "diy-part2 done."