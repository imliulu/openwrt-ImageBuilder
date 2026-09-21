# OpenWrt GL-MT3600BE ImageBuilder

基于 **OpenWrt 官方 Docker ImageBuilder** 为 GL.iNet GL-MT3600BE 构建定制 OpenWrt 固件。

当前默认目标：

- OpenWrt: `25.12.5`
- Target/Subtarget: `mediatek/filogic`
- Profile: `glinet_gl-mt3600be`
- 输出重点: `squashfs-sysupgrade.bin`

> OpenWrt 25.12 使用 `apk` 作为包管理器。此仓库优先使用 OpenWrt 官方软件源中的包，不直接混入来源不明的第三方 APK。

## 目录

```text
.
├── .github/workflows/build.yml     # GitHub Actions 构建入口
├── config/packages.txt             # 预装软件包清单
├── files/                          # 注入固件根文件系统的文件
│   └── etc/
│       └── uci-defaults/
│           └── 99-custom-init      # 首次启动配置
├── scripts/build.sh                # 容器内 ImageBuilder 构建脚本
├── scripts/build-local.sh          # 本地 Docker 构建脚本
└── dist/                           # CI 归档输出
```

## GitHub Actions 构建

进入仓库：

```text
Actions -> Build OpenWrt GL-MT3600BE -> Run workflow
```

输入：

| 参数 | 默认值 | 说明 |
|---|---|---|
| `openwrt_version` | `25.12.5` | OpenWrt 版本 |
| `firmware_version` | `1.0.0` | 内部固件版本 |
| `lan_ip` | `192.168.8.1` | 首次启动后的 LAN IP |
| `hostname` | `mt3600be` | 默认主机名 |

构建完成后从 Actions Artifact 下载固件。

## macOS / Linux 本地构建

依赖：

```text
Docker
Git
```

执行：

```bash
./scripts/build-local.sh
```

自定义：

```bash
OPENWRT_VERSION=25.12.5 \
FIRMWARE_VERSION=1.0.1 \
LAN_IP=192.168.8.1 \
HOSTNAME=mt3600be \
./scripts/build-local.sh
```

输出位于：

```text
bin/targets/mediatek/filogic/
```

## 增加软件包

编辑：

```text
config/packages.txt
```

每行一个软件包，例如：

```text
luci
curl
wireguard-tools
```

如果需要移除 ImageBuilder 默认软件包，可以使用：

```text
-ppp
```

建议先确认目标 OpenWrt 版本的软件源存在该包。

## 注入文件

`files/` 下的内容会按相同路径加入固件。

例如：

```text
files/etc/banner
```

最终成为：

```text
/etc/banner
```

批量部署建议把公共文件放在这里，但不要直接写入每台设备唯一的密钥或密码。

## 首次启动配置

`files/etc/uci-defaults/99-custom-init` 在首次启动时设置：

- hostname
- 时区
- LAN IPv4 地址

脚本成功退出后，OpenWrt 会自动清理该 uci-defaults 脚本。

## 查看构建信息

刷机后：

```bash
cat /etc/build-info
```

示例：

```text
FIRMWARE_VERSION='1.0.0'
OPENWRT_VERSION='25.12.5'
TARGET='mediatek/filogic'
PROFILE='glinet_gl-mt3600be'
BUILD_TIME='...'
GIT_COMMIT='...'
```

## 推荐刷机流程

从 GL.iNet 原厂系统切换到官方 OpenWrt 时，先使用设备对应的官方安装方法和 `sysupgrade` 镜像。批量自动化前至少先用 1~2 台设备验证完整流程。

建议自动化流程：

```text
上传固件
  -> sysupgrade -T 校验
  -> sha256 校验
  -> sysupgrade -n
  -> 等待设备重启
  -> 验证 /etc/openwrt_release
  -> 验证 /etc/build-info
  -> 记录 MAC / 固件版本 / 结果
```

不要在批量流程里使用 `sysupgrade -F` 绕过兼容性检查。

## 后续扩展建议

第一阶段保持 ImageBuilder 仓库简单。后续可以逐步增加：

1. 第三方 APK 下载、架构和签名校验。
2. Provision Server，按 MAC/SN 下发设备唯一配置。
3. 固件签名和内部 OTA。
4. 灰度升级与失败回滚。
5. 多型号 profile matrix。

## 安全建议

不要把以下内容提交到 Git：

```text
WireGuard Private Key
FRP Token
代理密码
设备证书私钥
生产环境 API Token
```

设备唯一凭据建议在首次启动后通过受认证的 Provision 服务下发。
