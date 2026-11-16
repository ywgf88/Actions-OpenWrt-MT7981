# Actions-OpenWrt-MT7981

基于 **GitHub Actions** 自动编译的 OpenWrt 固件，面向 MT7981B（MediaTek Filogic）平台的三款运营商 / 品牌定制路由器：

**CMCC RAX3000M**、**Qihoo 360T7** 与 **Cetron CT3003**

固件源码为 OpenWrt 官方仓库，分支 **v25.12.6**；预置 PassWall2 与 Vantage 主题，IPv4 单栈。

---

## 设备与固件分支

| 项目 | 内容 |
| --- | --- |
| 固件版本 | OpenWrt **v25.12.6**（官方源码 `openwrt/openwrt`，分支 `v25.12.6`） |
| 芯片平台 | MediaTek Filogic **MT7981B**（`mediatek/filogic`） |
| 设备 1 | **CMCC RAX3000M**（中国移动 RAX3000M，目标名 `cmcc_rax3000m`） |
| 设备 2 | **Qihoo 360T7**（奇虎 360 T7，目标名 `qihoo_360t7`） |
| 设备 3 | **Cetron CT3003**（目标名 `cetron_ct3003`，DTS `mt7981b-cetron-ct3003-ubootmod`，OpenWrt U-Boot / FIT 布局，产物为 `.itb`） |
| 编译方式 | 一次构建同时产出三款设备的固件（`CONFIG_TARGET_MULTI_PROFILE=y`） |
| 运行环境 | GitHub Actions `ubuntu-22.04`，单次构建超时上限 360 分钟 |

> 目标名以 OpenWrt 官方设备定义为准。刷机前请核对自己的硬件版本与目标名是否一致，尤其同型号存在不同存储版本时。

---

## 预置插件

**基础与界面**

- `luci` —— LuCI Web 管理界面
- `luci-app-firewall` —— 防火墙配置界面
- `luci-lib-jsonc` —— LuCI JSON 解析库
- `luci-theme-vantage` —— 默认主题（Vantage，源码取自 `anothaDev/luci-theme-vantage`）
- 界面语言：简体中文（`CONFIG_LUCI_LANG_zh_Hans=y`）

**代理工具**

- `luci-app-passwall2` —— PassWall2 分流代理
  - 代理核心：**Xray**（仅此一个核心）
  - 透明代理方式：**nftables**
  - 未编译：HAProxy、Shadowsocks-Rust、ShadowsocksR-libev、Simple-Obfs、V2ray-Plugin
  - 依赖源：`Openwrt-Passwall/openwrt-passwall-packages`（`main` 分支）
  - 插件源：`Openwrt-Passwall/openwrt-passwall2`（`main` 分支）

**家庭场景工具**

| 插件 | 作用 | 默认状态 |
| --- | --- | --- |
| `luci-app-sqm` | 智能限速排队（SQM/cake），防止单台设备占满带宽 | 编译进固件 |
| `luci-app-ddns` | 动态域名解析，宽带无固定公网 IP 时远程回家的前提 | 编译进固件 |
| `luci-app-wol` | 网络唤醒，远程开启 NAS 或台式机 | 编译进固件 |
| `luci-app-nlbwmon` | 按设备/IP 统计流量，定位谁在占用带宽 | 编译进固件 |
| `luci-app-upnp` | UPnP / NAT-PMP 端口自动映射，BT 与联机游戏用 | 编译进固件 |
| `luci-proto-wireguard` | WireGuard 远程接入，内核态实现，比 tailscale 更轻更快 | 编译进固件 |
| `luci-app-commands` | 网页中执行自定义命令，调试与脚本入口 | 编译进固件 |
| `luci-app-ttyd` | 网页终端（内置 ttyd，走 WebSocket），改配置看日志不用另开 SSH 工具 | 编译进固件 |
| `luci-app-dawn` | 802.11k/v/r 快速漫游，多 AP 组网时终端不来回断线 | 编译进固件 |
| `luci-app-wifischedule` | 按时间段开关 Wi-Fi 射频（夜间关闭 Wi-Fi） | 编译进固件 |
| `zerotier` | ZeroTier 组网，无公网 IP 也能远程回家；官方无 LuCI 界面，用 `zerotier-cli` / `uci` 配置 | 编译进固件 |

以上插件连同各自的中文语言包一并编入镜像。若嫌固件变大，把 `.config` 里对应 `CONFIG_PACKAGE_*` 行删掉或改成 `is not set` 即可。

**未包含（为控制体积刻意裁掉）**

- `luci-app-vantage` —— Vantage 主题的配套设置面板（仅编译主题本体）
- 全部 IPv6 组件：`odhcp6c`、`odhcpd-ipv6only`、`luci-proto-ipv6`、`ipv6helper`、`6in4`、`6to4`

---

## 默认配置

| 项目 | 默认值 |
| --- | --- |
| **默认 IP 地址** | **`192.168.6.1`**（由 `diy-part2.sh` 改写 `config_generate` 得到，DHCP 网段同源，LAN 网关） |
| 默认登录 | 用户名 `root`，密码为空（首次登录请立即设置） |
| **默认主题** | **Vantage**（已剔除 `luci-theme-bootstrap` 依赖） |
| 界面语言 | 简体中文 |
| 时区 | `CST-8`（China Standard Time，UTC+8） |
| 网络栈 | IPv4 单栈，不生成任何 IPv6 地址段与 `wan6` 接口 |

**想把默认 IP 改成别的网段**（例如 `192.168.100.1`）：

编辑 `diy-part2.sh` 第 3 条即可——它现在已经把 `config_generate` 里的 `192.168.1.1` 全局替换成 `192.168.6.1`，把这行的两个数字改成你要的网段，重新触发构建：

```bash
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate
```

---

## 构建方式

仅支持**手动触发**：

1. 打开仓库 **Actions** 页面，选择工作流 **OpenWrt Builder**；
2. 点击 **Run workflow**，选择 `main` 分支后确认；
3. 等待构建完成（首次全量编译耗时较长，通常在 1～3 小时）。

构建流程依次为：检出配置 → 拉取 OpenWrt 源码（`v25.12.6`）→ 载入自定义 feeds → `feeds update -a` → `feeds install -a` → 载入 `.config` 并执行 `diy-part2.sh` → **校验目标设备是否被正确选中** → 下载软件包 → 编译 → 上传产物。

其中 `Validate target config` 一步会强制检查三款设备是否都出现在最终 `.config` 中；若某一款被 `make defconfig` 丢弃，构建会立即失败并在日志中提示，避免产出缺设备的"半成品"。为防这种静默丢弃，该步骤会先把 `.config` 的换行符统一为 LF，执行一次 `make defconfig`，然后检查三款设备的 `DEVICE_` 符号，发现哪个被丢弃就直接补写回 `.config`，再重新 `make defconfig` 解析一次，最后用 grep 硬校验。

> 旧教程里的 `./scripts/config -e` 在 v25.12.2 上不可用：`scripts/config` 已经是目录而不是可执行脚本，调用会报 `Is a directory` / exit 126。

---

## 产物与 Release

- **固件位置**：`bin/targets/mediatek/filogic/`
- **文件名**：`*squashfs-sysupgrade.itb`（三款设备统一为 FIT 打包，不再有 `.bin`；RAX3000M 的 eMMC 变体产物会被构建脚本剔除）
- **CT3003 不产出 `factory.bin`**：上游 `cetron_ct3003` 定义里的 `factory.bin`（`cetron-header rd30 CT3003` 头）是给**原厂 U-Boot + stock 分区布局**用的，本仓库把该设备整块替换成了 OpenWrt U-Boot / FIT 布局（128 MB `ubi` 卷 `fit`、`root=/dev/fit0`），与 OEM 恢复流程写入的 stock 布局不兼容。把 `.itb` 包上 cetron 头虽然能通过 OEM 的头校验，但刷进去起不来，属危险产物，因此不生成。
- **Release 命名**：`年.月.日-时分`（例：`2026.11.08-1530`）
- **Release 保留策略**：只保留最新 **3** 个，更早的 tag 与附件自动删除
- **Artifacts**：同时上传完整固件目录，便于不发布 Release 时也能下载

构建成功后，请到 **Releases** 页面下载对应自己设备的 `sysupgrade.itb`；CT3003 需先由 OpenWrt U-Boot（ubootmod）写入该 `.itb`，本仓库不提供原厂固件首刷包。

---

## CT3003 升级（UBI 卷名陷阱）

CT3003 的 DTS（`mt7981b-cetron-ct3003-ubootmod`）把 128 MB 的 `ubi` 分区拆成下列卷，**U-Boot 与内核都按"卷名"取镜像**：

| 卷名 | 作用 |
| --- | --- |
| `fit` | 生产镜像 —— U-Boot 的 `ubi_read_production=ubi read $loadaddr fit` 和内核 `root=/dev/fit0` 都读它 |
| `recovery` | 恢复用 initramfs，生产镜像引导失败时自动兜底（`boot_ubi=run boot_production ; run boot_recovery ; ...`） |
| `ubootenv` / `ubootenv2` | U-Boot 环境变量双备份 |
| `rootfs_data` | overlay（squashfs 之外的持久化层） |

### 坑在哪

在运行系统里直接 `sysupgrade`，由于本设备不在上游 `platform.sh` 的任何设备列表里、掉进末尾的默认分支，而 `nand.sh` 的 `CI_KERNPART` 默认值是 `kernel` —— 整个 FIT 会被写进一个**名为 `kernel` 的卷**，引导只读 `fit`，于是**刷完重启，版本一点没变**，`/etc/openwrt_release` 和 `uname -a` 还是旧的。

（对照：上游的 `cmcc,rax3000m`、`qihoo,360t7`、`qihoo,360t7-ubi` 走的是 `fit_do_upgrade`，卷名由设备树里的 `chosen/rootdisk` 决定，所以 RAX3000M 与 360T7 从来没有这个毛病。根因与修法见下面「以后升级」一节。）

同时，若 `fit` 卷偏小（首次实测为 214 LEBs = 25.9 MiB，而 v25.12.6 镜像 30.0 MiB），卷容量也塞不下，且**无法在运行系统里扩容**：`fit` 被 ubiblock 映射挂载为 `/rom`、`rootfs_data` 正在作 overlay，对它们执行 `ubirsvol` 一律返回 `error 16 (Resource busy)`；`available LEBs = 0` 也没有空隙可分。

**升级后版本没变时，先定位镜像落在哪个卷里**：

```sh
ubinfo -a                                     # 看每个卷的 ID / 名称 / LEB 数
dd if=/dev/ubi0_0 of=/tmp/k.bin bs=1M count=2 2>/dev/null
strings /tmp/k.bin | grep -m1 -i 'Linux-6\.'   # 该卷里是哪一版内核
```

逐个卷读一遍即可看出：新镜像躺在哪个卷、名为 `fit` 的卷里是不是还装着旧镜像。

### 正确做法一（标准）：交给 U-Boot 自己写

U-Boot 环境变量里已有正确流程，它会"删旧卷 → 按镜像实际大小重建 → 写入"，天生不会容量不足：

```
bootmenu_4            = Load production system via TFTP then write to NAND
ubi_write_production  = ubi check fit && ubi remove fit ; run ubi_remove_rootfs ;
                        ubi create fit $filesize dynamic && ubi write $loadaddr fit $filesize
```

操作步骤：

1. 串口（USB-TTL，3.3V）接板子，开机进 U-Boot `bootmenu`，选第 **4** 项；
2. PC 网卡临时设为 `192.168.1.254`（U-Boot 里 `serverip=192.168.1.254`，`ipaddr=192.168.1.1`），起一个 TFTP 服务；
3. TFTP 目录里放改名后的镜像：`immortalwrt-mediatek-filogic-cetron_ct3003-ubootmod-squashfs-sysupgrade.itb`（这是环境变量 `bootfile_upg` 期望的文件名，把本仓库产出的 `.itb` 改个名即可）。

### 正确做法二（救急）：互换卷名

新镜像其实已经写进某个卷、只是卷名不对时，用 `ubirename` 原子互换两个卷名即可，**数据一个字节都不动**：

```sh
ubirename /dev/ubi0 fit kernel kernel fit
```

要点：

- 执行前后都用 `ubinfo -a` 确认：**名为 `fit` 的那个卷必须是 248 LEBs（装着新镜像的那个）**；
- 旧镜像完整留在另一个卷里 —— 想回滚，把同一条命令**再执行一次**即可（互换语义，执行两次等于没换）；
- 当前系统正在跑的 `/rom` 是 ubiblock 按**卷 ID** 绑定的，换名不影响当次运行，重启后才按新名字找镜像；
- 换名后不再需要那个 `kernel` 卷，确认新固件稳定后可回收空间：`ubirmvol /dev/ubi0 -N kernel`（约 25.9 MiB）。

### 以后升级：LuCI 里点一下（依赖 `diy-part2.sh` 第 6 条补丁）

`diy-part2.sh` 第 6 条只做一件事：在源码 `target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh` 的 `platform_do_upgrade` 里，把 `cetron,ct3003-ubootmod` 归入上游那组 FIT 设备（`fit_do_upgrade "$1"`）。上游这个函数（来自 `fitblk` 包的 `/lib/upgrade/fit.sh`）会：

1. 读设备树 `chosen/rootdisk` 指向的 UBI 卷，把它的 `volname`（本设备是 `fit`）导出成 `CI_KERNPART`；
2. 先 `fitblk /dev/fit0` 释放块设备，让该卷可以被删掉、重建；
3. 删掉 `fit` 与 `rootfs_data`，按新镜像实际长度重建 `fit`、剩余空间全部留给 `rootfs_data`，写入 FIT，恢复配置并重启。

所以升级回到标准动作，**不需要 `kernel` 卷、也不需要 `ubirename`**。上游的 `cmcc,rax3000m`、`qihoo,360t7`、`qihoo,360t7-ubi` 本来就在这个列表里——RAX3000M 和 360T7 从来没有这个毛病。

**LuCI**：系统 → 备份/刷机固件 → 选 `...-squashfs-sysupgrade.itb` → 勾选「保留配置并保留当前配置」、取消勾选「强制刷写」→ 刷写 → 自动重启一次，直接进新版本。

**SSH**（等价，一条命令）：

```sh
sysupgrade /tmp/openwrt-25.12.x-mediatek-filogic-cetron_ct3003-squashfs-sysupgrade.itb
```

| LuCI 选项 | 怎么选 | 对应参数 |
| --- | --- | --- |
| 「保留配置并保留当前配置」 | **勾上** | 勾上不加 `-n`；默认未勾，等于 `-n`（清空配置） |
| 「强制刷写」 | **取消勾选** | `--force`；只在校验失败且确认镜像对版时才勾 |
| 固件文件 | 只能选 `...-squashfs-sysupgrade.itb` | 别选 `...-initramfs-recovery.itb` |

补丁生效的前提是**设备上跑的是带该补丁的固件**：`platform.sh` 属于运行系统的一部分，所以当前这台（用旧逻辑刷进来的）下次仍要走上面的做法一或做法二；等装上带补丁的那一版之后，才变成"点一下就完"。

四点提醒：

1. 升级前先 `sysupgrade -b /tmp/cfg.tar.gz` 备份配置（补丁已在实机跑过完整升级，但每次都会重建 `rootfs_data`，备份是唯一兜底）；
2. 任何一次 `sysupgrade` 都会重建 `rootfs_data`，配置靠 `/tmp/sysupgrade.tgz` 恢复；真出问题会由 `recovery` 卷自动兜底引导，不会变砖；
3. 若日后 `DEVICE_COMPAT_VERSION` 变化，LuCI 会禁用「保留配置」并提示布局变化，那一次只能用 `-n`；
4. 设备上如果还留着上次救急用的 `kernel` 卷（214 LEBs，装着 25.12.2 旧镜像），确认新固件稳定后可回收空间：`ubirmvol /dev/ubi0 -N kernel`（约 25.9 MiB）；不删也能用，只是白占。

### 装好之后的验收清单

带补丁的这一版刷进去后（第一次仍要 `sysupgrade` + `ubirename`，见上），逐条核对：

| # | 命令 | 期望 |
| --- | --- | --- |
| 1 | `cat /etc/openwrt_release` | `DISTRIB_RELEASE='25.12.6'`、`DISTRIB_REVISION='r33311-981c978eff'` |
| 2 | `grep -c 'cetron,ct3003-ubootmod)' /lib/upgrade/platform.sh` | `1` —— 补丁确实在固件里 |
| 3 | `ls /sys/firmware/devicetree/base/chosen/rootdisk` | 文件存在 |
| 4 | `ubinfo -a` | `fit` 卷为 248 LEBs |
| 5 | 下面的"取卷名预演"脚本 | `volname=fit ubipart=ubi method=ubi` |

第 2 条是唯一能区分新旧固件的判据 —— 两个镜像的内核号都是 6.12.112，`uname -a` 看不出来。

第 5 条最关键：它复刻 `fit_do_upgrade` 内部 `export_fitblk_bootdev()` 的查找过程，输出正确就说明下次一键升级能拿到对卷名。

```sh
sh -c '
rootdisk="$(cat /sys/firmware/devicetree/base/chosen/rootdisk)"
for h in /sys/class/mtd/mtd*/of_node/volumes/*/phandle; do
  [ -e "$h" ] || continue
  if [ "$rootdisk" = "$(cat "$h")" ]; then
    echo "volname=$(cat "${h%/phandle}/volname") ubipart=$(cat "${h%%/of_node*}/name") method=ubi"
    exit 0
  fi
done
echo "no match"'
```

然后补一条配置，把运行系统的布局版本记成 1.2：

```sh
uci set system.@system[0].compat_version='1.2'
uci commit system
```

> **为什么必须记**：`/lib/upgrade/fwtool.sh` 做题图比较时读的是 `uci get system.@system[0].compat_version`，读不到就按 **1.0** 算；而新镜像带的是 `DEVICE_COMPAT_VERSION := 1.2`（`dts/ct3003-ubootmod-body.mk`）。大版本相同、只差次版本时，sysupgrade 只允许"不保留配置"刷，表现就是：
>
> ```
> The device is supported, but the config is incompatible to the new image (1.0->1.2).
> Please upgrade without keeping config (sysupgrade -n).
> Flash layout changes require bootloader update
> Image check failed.
> ```
>
> 首次刷带补丁的固件时一定会遇到（因为旧固件从不写这个字段）。两种处理方式：
>
> - **保留配置**（推荐，布局其实没变）：`sysupgrade --ignore-minor-compat-version /tmp/xxx.itb`。v25.12.6 起的 `sysupgrade` 自带该开关，只跳过次版本检查，大版本不同仍会拦；
> - **干净刷**：`sysupgrade -n /tmp/xxx.itb`。配置会清空，先把备份拉到电脑上 —— `/tmp` 是内存，重启即失：`scp root@192.168.6.1:/tmp/cfg-ct3003.tar.gz .`
>
> 记下 `compat_version=1.2` 之后，后续升级直接勾「保留配置」就不会再被拦。

最后：确认新固件稳定几天后回收旧卷，把空间还给 overlay：

```sh
ubirmvol /dev/ubi0 -N kernel     # 约 30 MiB（248 LEBs）
```

### 实机验证记录

| 项目 | 值 |
| --- | --- |
| 设备 | Cetron CT3003（`cetron_ct3003`，自建 ubootmod） |
| 升级路径 | 25.12.2（`r32802-f505120278` / 6.12.74）→ **25.12.6（`r33311-981c978eff` / 6.12.112）** |
| 完成方式 | `sysupgrade -n` 写入后镜像落在 `kernel` 卷，通过 `ubirename` 互换卷名完成引导 |
| `fit` 卷 | 248 LEBs（31 490 048 B），容纳 31 429 203 B 的镜像 |
| 验证项 | ttyd 1.7.7 / dawn 2025.11.07 / wifischedule 1.1.0 / zerotier 1.16.2 均已安装；radio0（2.4G HE20）与 radio1（5G HE80）正常 up |
| 升级补丁 | `diy-part2.sh` 第 6 条：把 `cetron,ct3003-ubootmod` 并入上游 `fit_do_upgrade` 列表（只加 3 行） |
| 补丁版固件 | Release `2026.11.16-0054`（commit `926de3a`）；`sysupgrade --ignore-minor-compat-version` 后 `ubirename` 换名，引导成功 |
| 取卷名预演 | `volname=fit ubipart=ubi method=ubi`，与 `fit_do_upgrade` 内部 `export_fitblk_bootdev()` 的解析结果一致 |
| `compat_version` | 运行系统已写入 `1.2`，后续 LuCI 勾「保留配置」不再被次版本校验拦截 |
| 一键升级实测 | 2026-11-16 在 LuCI 里勾「保留配置」刷同一份 `2026.11.16-0054`：**只重启一次**，`REVISION` 不变（同一镜像），`compat_version=1.2` 原样保留 |
| 卷重建证据 | `rootfs_data` 从 `/dev/ubi0_5` 变为 `/dev/ubi0_1`（说明该卷被删除重建），overlay 由 35.2M 涨到 62.9M（回收出的 248 LEBs 空池全并入） |
| 空间回收 | `ubirmvol /dev/ubi0 -N kernel` 后卷数 6→5、available 回到 0、无 `kernel` 卷残留 |

---

## 快速试机构建（ImageBuilder，几分钟一版）

`imagebuilder-fast.yml` 用官方 ImageBuilder 拼镜像：**不编内核、不编软件包**，只做"解包 → 装已编好的二进制包 → 叠加 `files/` 覆盖层 → 打包"，一版几分钟（大头是下载 550 MB 的 imagebuilder 包）。

| 项目 | 说明 |
| --- | --- |
| 入口 | Actions → **ImageBuilder 快速试机** → Run workflow |
| 可选 profile | `cmcc_rax3000m`、`qihoo_360t7`、`qihoo_360t7-ubi` |
| 额外包 | `extra_packages` 输入框，空格分隔，例 `luci-app-sqm luci-i18n-sqm-zh-cn` |
| 产物 | workflow artifact（`.itb` + 引导工件，保留 14 天），同时打印 SHA256 |
| 默认值 | `imagebuilder/files/etc/uci-defaults/99-aom-defaults.sh`：时区 `CST-8`、LAN 改 `192.168.6.1`、IPv4 单栈 |
| 默认包集 | luci + 中文语言包、ttyd、dawn、zerotier、wifischedule、openssh-sftp-server（25.12 的 luci 源里已没有 `luci-app-zerotier`，只装 `zerotier` 本体） |

**它做不到的事**（所以 CT3003 不能走这条）：

- 动不了 DTS、内核配置、`base-files`、`platform.sh` —— 布局和升级逻辑都在源码层，ImageBuilder 里根本没有；
- 版本固定在 25.12.6，上游发新版要同时改 `TARGET_URL` 和 `IB_TARBALL` 两处；
- 只能用官方仓库里已编好的包，自定义内核模块编不了；
- 包只能来自 25.12.6 官方 release 源（`targets/.../kmods` + `base`/`luci`/`packages`/`routing`/`telephony`/`video` 六个 feed）。第三方包（homeproxy、argon 主题、OAF 等）不在里面，写进 `extra_packages` 会在组装步骤直接报 `unable to select packages: xxx (no such package)` 并失败（首跑失败就是这个原因：`luci-app-zerotier` 在 25.12 源里已不存在）。

**什么时候用它**：想试"某个插件装上能不能跑"，或给 RAX3000M / 360T7 快速出一版先验证；确认好用后再改 `.config` 走正式构建（那套要 1.5 小时）。CT3003 永远走正式构建。

刷之前先确认 profile 与设备布局一致，刷错会起不来：

```sh
cat /tmp/sysinfo/board_name     # cmcc,rax3000m / qihoo,360t7 / qihoo,360t7-ubi
```

进 Recovery 的依据：产物里必须有 `<profile>-squashfs-sysupgrade.itb`（RAX3000M 约 15 MB、360T7 约 14 MB），外加 `bl31-uboot.fip` / `preloader.bin`（RAX3000M 还多一套 emmc/nand 变体和 `gpt.bin`）。ImageBuilder 本来就不产 `-initramfs-recovery.itb`，没有它不是打包失败；缺 `sysupgrade.itb` 或体积明显偏小才算失败，别刷。

---

## 仓库结构

```
├── .github/workflows/
│   ├── openwrt-builder.yml   # 正式构建：源码编译 + 发布 Release
│   └── imagebuilder-fast.yml # 快速试机：只组装已有二进制，几分钟一版（CT3003 不适用）
├── .config                    # 编译配置：目标设备、插件、主题、版本信息
├── diy-part1.sh               # feeds 更新前执行：加 PassWall2 与 Vantage 源
├── diy-part2.sh               # feeds 安装后执行：改默认主题、时区、IPv4 单栈、CT3003 升级路径
├── imagebuilder/files/        # 试机镜像的 files 覆盖层（uci-defaults 脚本）
└── README.md
```

两个 diy 脚本的分工很关键：

- **diy-part1.sh**（`feeds update/install` 之前）：向 `feeds.conf.default` 追加 PassWall2 的两个源，并把 Vantage 主题源码直接 `clone` 进 `package/`。因为官方 feed 里既没有 `xray-core` 这类依赖，也没有 Vantage 主题。
- **diy-part2.sh**（`feeds install` 之后）：把 LuCI 集合包里的 `luci-theme-bootstrap` 依赖替换成 `luci-theme-vantage`；把默认时区从 `GMT0` 改成 `CST-8`；通过屏蔽 `/proc/sys/net/ipv6` 判断让 `config_generate` 完全不生成 IPv6 配置；把 CT3003 换成 ubootmod/FIT 设备定义；改写 `platform.sh` 修正 CT3003 的升级路径（详见「CT3003 升级」一节）。

---

## 常见改动

| 需求 | 改哪里 |
| --- | --- |
| 换默认 IP 网段 | `diy-part2.sh` 第 3 条 `sed` |
| 换默认主题 | `.config` 里 `CONFIG_PACKAGE_luci-theme-*` + `diy-part2.sh` 第 1 条替换串 |
| 增加/删除插件 | `.config` 中增删 `CONFIG_PACKAGE_xxx=y` / `not set` |
| 改源码分支 | 工作流 `env.REPO_BRANCH` |
| 加代理核心（SS/SSR/Trojan） | `.config` 中打开对应的 `luci-app-passwall2_INCLUDE_*` 开关 |
| 保留更多旧 Release | 工作流 `keep_latest` |

---

## 刷机提示

- 本仓库只负责**编译**固件，不提供刷机包适配与救砖服务，刷机有风险。
- 升级建议走 LuCI 的「系统 → 备份与升级」，用 `sysupgrade` 文件，**不要**保留旧配置跨大版本升级（尤其是从带 IPv6 的固件切到本 IPv4 单栈固件）。
- **CT3003** 已是 OpenWrt U-Boot / FIT 布局，但**不要直接在 LuCI 里 `sysupgrade`**：镜像会写进错误的 UBI 卷，导致"刷完版本一点没变"，原因与正确做法见上文「CT3003 升级（UBI 卷名陷阱）」。本仓库不产出原厂固件首刷用的 `factory.bin`。
- 首次进入系统后请立刻到「系统 → 管理权」设置 root 密码，并在 PassWall2 中自行导入节点/订阅。

---

## 参考来源

- OpenWrt 官方源码：<https://github.com/openwrt/openwrt>
- PassWall2 插件：<https://github.com/Openwrt-Passwall/openwrt-passwall2>
- PassWall2 依赖：<https://github.com/Openwrt-Passwall/openwrt-passwall-packages>
- Vantage 主题：<https://github.com/anothaDev/luci-theme-vantage>
