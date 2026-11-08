# Actions-OpenWrt-MT7981

基于 **GitHub Actions** 自动编译的 OpenWrt 固件，面向 MT7981B（MediaTek Filogic）平台的三款运营商 / 品牌定制路由器：

**CMCC RAX3000M**、**Qihoo 360T7** 与 **Cetron CT3003**

固件源码为 OpenWrt 官方仓库，分支 **v25.12.2**；预置 PassWall2 与 Vantage 主题，IPv4 单栈，成品体积控制在 58MB 以内。

---

## 设备与固件分支

| 项目 | 内容 |
| --- | --- |
| 固件版本 | OpenWrt **v25.12.2**（官方源码 `openwrt/openwrt`，分支 `v25.12.2`） |
| 芯片平台 | MediaTek Filogic **MT7981B**（`mediatek/filogic`） |
| 设备 1 | **CMCC RAX3000M**（中国移动 RAX3000M，目标名 `cmcc_rax3000m`） |
| 设备 2 | **Qihoo 360T7**（奇虎 360 T7，目标名 `qihoo_360t7`） |
| 设备 3 | **Cetron CT3003**（目标名 `cetron_ct3003`，DTS `mt7981b-cetron-ct3003`，NAND + UBINIZE 布局） |
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

**未包含（为控制体积刻意裁掉）**

- `luci-app-ttyd` —— 网页终端
- `luci-app-vantage` —— Vantage 主题的配套设置面板（仅编译主题本体）
- 全部 IPv6 组件：`odhcp6c`、`odhcpd-ipv6only`、`luci-proto-ipv6`、`ipv6helper`、`6in4`、`6to4`

---

## 默认配置

| 项目 | 默认值 |
| --- | --- |
| **默认 IP 地址** | **`192.168.1.1`**（DHCP 网段同源，LAN 网关） |
| 默认登录 | 用户名 `root`，密码为空（首次登录请立即设置） |
| **默认主题** | **Vantage**（已剔除 `luci-theme-bootstrap` 依赖） |
| 界面语言 | 简体中文 |
| 时区 | `CST-8`（China Standard Time，UTC+8） |
| 网络栈 | IPv4 单栈，不生成任何 IPv6 地址段与 `wan6` 接口 |
| 固件体积上限 | 58MB（超出则构建直接失败） |

**想把默认 IP 改成别的网段**（例如 `192.168.100.1`）：

编辑 `diy-part2.sh`，取消第 3 条的注释并改数字，重新触发构建即可：

```bash
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate
```

---

## 构建方式

仅支持**手动触发**：

1. 打开仓库 **Actions** 页面，选择工作流 **OpenWrt Builder**；
2. 点击 **Run workflow**，选择 `main` 分支后确认；
3. 等待构建完成（首次全量编译耗时较长，通常在 1～3 小时）。

构建流程依次为：检出配置 → 拉取 OpenWrt 源码（`v25.12.2`）→ 载入自定义 feeds → `feeds update -a` → `feeds install -a` → 载入 `.config` 并执行 `diy-part2.sh` → **校验目标设备是否被正确选中** → 下载软件包 → 编译 → 检查固件体积 → 上传产物。

其中 `Validate target config` 一步会强制检查三款设备是否都出现在最终 `.config` 中；若某一款被 `make defconfig` 丢弃，构建会立即失败并在日志中提示，避免产出缺设备的"半成品"。为防这种静默丢弃，该步骤会先把 `.config` 的换行符统一为 LF，在第一次 `make defconfig` 加载 target 菜单之后，再用 `./scripts/config -e` 逐条显式启用三款设备，然后重新 `make defconfig`。

---

## 产物与 Release

- **固件位置**：`bin/targets/mediatek/filogic/`
- **文件名**：`*squashfs-sysupgrade.itb` 或 `*squashfs-sysupgrade.bin`（依设备而定；三者均为 `sysupgrade-tar` 打包）
- **CT3003 额外产物**：`*.factory.bin`（带 `cetron-header rd30 CT3003` 头，用于从原厂固件首次刷入）
- **Release 命名**：`年.月.日-时分`（例：`2026.11.08-1530`）
- **Release 保留策略**：只保留最新 **3** 个，更早的 tag 与附件自动删除
- **Artifacts**：同时上传完整固件目录，便于不发布 Release 时也能下载

构建成功后，请到 **Releases** 页面下载对应自己设备的 `sysupgrade` 文件；CT3003 首次从原厂固件迁移时用 `factory.bin`。

---

## 仓库结构

```
├── .github/workflows/
│   └── openwrt-builder.yml   # 唯一工作流：编译、校验体积、发布 Release
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
| 放开固件体积 | 工作流 `env.MAX_FIRMWARE_MB` |
| 改源码分支 | 工作流 `env.REPO_BRANCH` |
| 加代理核心（SS/SSR/Trojan） | `.config` 中打开对应的 `luci-app-passwall2_INCLUDE_*` 开关 |
| 保留更多旧 Release | 工作流 `keep_latest` |

---

## 刷机提示

- 本仓库只负责**编译**固件，不提供刷机包适配与救砖服务，刷机有风险。
- 升级建议走 LuCI 的「系统 → 备份与升级」，用 `sysupgrade` 文件，**不要**保留旧配置跨大版本升级（尤其是从带 IPv6 的固件切到本 IPv4 单栈固件）。
- **CT3003** 从原厂固件迁移时用 `factory.bin`；之后升级与其他两款设备一样用 `sysupgrade`。
- 首次进入系统后请立刻到「系统 → 管理权」设置 root 密码，并在 PassWall2 中自行导入节点/订阅。

---

## 参考来源

- OpenWrt 官方源码：<https://github.com/openwrt/openwrt>
- PassWall2 插件：<https://github.com/Openwrt-Passwall/openwrt-passwall2>
- PassWall2 依赖：<https://github.com/Openwrt-Passwall/openwrt-passwall-packages>
- Vantage 主题：<https://github.com/anothaDev/luci-theme-vantage>
