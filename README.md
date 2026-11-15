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

在运行系统里直接 `sysupgrade`，整个 FIT 会被写进名为 **`kernel`** 的卷（旧装机残留的卷名），而引导只读 `fit` —— 于是**刷完重启，版本一点没变**，`/etc/openwrt_release` 和 `uname -a` 还是旧的。

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

### 实机验证记录

| 项目 | 值 |
| --- | --- |
| 设备 | Cetron CT3003（`cetron_ct3003`，自建 ubootmod） |
| 升级路径 | 25.12.2（`r32802-f505120278` / 6.12.74）→ **25.12.6（`r33311-981c978eff` / 6.12.112）** |
| 完成方式 | `sysupgrade -n` 写入后镜像落在 `kernel` 卷，通过 `ubirename` 互换卷名完成引导 |
| `fit` 卷 | 248 LEBs（31 490 048 B），容纳 31 429 203 B 的镜像 |
| 验证项 | ttyd 1.7.7 / dawn 2025.11.07 / wifischedule 1.1.0 / zerotier 1.16.2 均已安装；radio0（2.4G HE20）与 radio1（5G HE80）正常 up |

---

## 仓库结构

```
├── .github/workflows/
│   └── openwrt-builder.yml   # 唯一工作流：编译、发布 Release
├── .config                    # 编译配置：目标设备、插件、主题、版本信息
├── diy-part1.sh               # feeds 更新前执行：加 PassWall2 与 Vantage 源
├── diy-part2.sh               # feeds 安装后执行：改默认主题、时区、IPv4 单栈
└── README.md
```

两个 diy 脚本的分工很关键：

- **diy-part1.sh**（`feeds update/install` 之前）：向 `feeds.conf.default` 追加 PassWall2 的两个源，并把 Vantage 主题源码直接 `clone` 进 `package/`。因为官方 feed 里既没有 `xray-core` 这类依赖，也没有 Vantage 主题。
- **diy-part2.sh**（`feeds install` 之后）：把 LuCI 集合包里的 `luci-theme-bootstrap` 依赖替换成 `luci-theme-vantage`；把默认时区从 `GMT0` 改成 `CST-8`；通过屏蔽 `/proc/sys/net/ipv6` 判断让 `config_generate` 完全不生成 IPv6 配置。

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
