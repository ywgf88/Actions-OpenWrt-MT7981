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
#          （root=/dev/fit0）都只按卷名 "fit" 取镜像；而 nand.sh 里
#          CI_KERNPART="${CI_KERNPART:-kernel}"，上游 filogic 的 platform.sh 只给
#          unielec,u7981-01* 设过 CI_KERNPART="fit"，本设备掉进默认分支，
#          于是整个 FIT 被写进名为 kernel 的卷，引导根本不读它。
#    做法：把原 platform_do_upgrade 改名为 _platform_do_upgrade，再在文件末尾追加
#          一个只针对 cetron,ct3003-ubootmod 的覆盖函数：
#          ① 仍按默认路径把 FIT 写进 kernel 卷——该卷此时未被挂载，不会 EBUSY，
#             且 nand.sh 会删掉旧卷后按镜像实际大小重建，容量永不受限；
#          ② 写完后用 ubirename 原子互换 fit / kernel 两个卷名（只改名不动数据）；
#          ③ 照常恢复配置并重启，重启后 U-Boot 读到的 fit 卷即为新镜像。
#          另外两款设备不受影响，仍走原函数。
UPG=target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh
if [ -f "$UPG" ] && ! grep -q '_platform_do_upgrade()' "$UPG"; then
  sed -i 's/^platform_do_upgrade() {/_platform_do_upgrade() {/' "$UPG"
  cat >> "$UPG" <<'PLATFORM_EOF'

# --- Actions-OpenWrt-MT7981 ---
# cetron_ct3003（自建 ubootmod 布局）专用升级路径，详见仓库 diy-part2.sh 第 6 条。
platform_do_upgrade() {
	if [ "$(board_name)" != "cetron,ct3003-ubootmod" ]; then
		_platform_do_upgrade "$@"
		return $?
	fi

	local file="$1"
	local cmd="$(identify_if_gzip "$file")cat"

	if [ "$(identify "$file" "$cmd" "")" != "fit" ]; then
		nand_do_upgrade "$file"
		return $?
	fi

	local ubidev="$(nand_find_ubi "${CI_KERN_UBIPART:-ubi}")"
	local kernvol="$(nand_find_volume "$ubidev" kernel)"
	local lebsz="$(cat "/sys/class/ubi/$ubidev/eraseblock_size" 2>/dev/null)"
	local avail="$(cat "/sys/class/ubi/$ubidev/avail_eraseblocks" 2>/dev/null)"

	# 预检：把就地删除的 kernel 卷也算进可用空间，避免删完 rootfs_data 才发现放不下
	if [ -n "$lebsz" ] && [ -n "$avail" ]; then
		local need=$(( ($cmd < "$file" | wc -c) / lebsz + 1 ))
		[ -n "$kernvol" ] && avail=$(( avail + $(cat "/sys/class/ubi/$kernvol/reserved_ebs" 2>/dev/null || echo 0) ))
		if [ "$avail" -lt "$need" ]; then
			echo "not enough free UBI space for a kernel volume (need $need LEBs, have $avail)."
			echo "please upgrade from U-Boot bootmenu_4 (TFTP) instead."
			nand_do_upgrade_failed
			return 1
		fi
	fi

	CI_KERNPART="kernel"
	nand_verify_if_gzip_file "$file" "$cmd" || nand_do_upgrade_failed
	nand_upgrade_fit "$file" "$cmd" || nand_do_upgrade_failed

	if ! ubirename /dev/$ubidev fit kernel kernel fit; then
		echo "cannot swap fit/kernel UBI volume names"
		nand_do_upgrade_failed
	fi

	nand_do_upgrade_success
}
PLATFORM_EOF
fi

grep -q '_platform_do_upgrade()' "$UPG" 2>/dev/null || { echo "ERROR: platform.sh 改造失败（未找到 _platform_do_upgrade）"; exit 1; }
grep -q 'cetron,ct3003-ubootmod' "$UPG" 2>/dev/null || { echo "ERROR: platform.sh 改造失败（缺少 cetron 分支）"; exit 1; }
echo "CT3003 升级路径已修正：写入 kernel 卷后自动互换 fit/kernel 卷名再重启"

echo "diy-part2 done."
