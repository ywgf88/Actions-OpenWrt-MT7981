
define Device/cetron_ct3003-ubootmod
	DEVICE_VENDOR := Cetron
	DEVICE_MODEL := CT3003
	DEVICE_VARIANT := (OpenWrt U-Boot layout)
	DEVICE_DTS := mt7981b-cetron-ct3003-ubootmod
	DEVICE_DTS_DIR := ../dts
	DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
	UBINIZE_OPTS := -E 5
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	KERNEL_IN_UBI := 1
	UBOOTENV_IN_UBI := 1
	IMAGES := sysupgrade.itb
	KERNEL_INITRAMFS_SUFFIX := -recovery.itb
	KERNEL := kernel-bin | gzip
	KERNEL_INITRAMFS := kernel-bin | lzma | \
		fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
	IMAGE/sysupgrade.itb := append-kernel | \
		fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
	DEVICE_COMPAT_VERSION := 1.2
	DEVICE_COMPAT_MESSAGE := Flash layout changes require bootloader update
endef
TARGET_DEVICES += cetron_ct3003-ubootmod
