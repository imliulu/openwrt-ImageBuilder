# OpenWrt GL-MT3600BE ImageBuilder

用于 GL.iNet GL-MT3600BE 的 OpenWrt 固件构建仓库。

当前生产测试阶段使用 **OpenWrt 主线 SNAPSHOT**，原因是已实测 25.12.5 / 25.12-SNAPSHOT 在该设备 RTL8221B WAN 口 1Gbps 模式下存在严重丢包，而已验证的主线 SNAPSHOT 工作正常。待后续稳定版包含修复后再切回 stable。

## Golden / Recovery Image 目标

初始固件保持尽可能精简，只保证：

- 官方 OpenWrt SNAPSHOT 默认系统
- LuCI Web 管理界面
- FRP Client (`frpc`)
- WAN 使用 OpenWrt 默认 DHCP 配置
- Factory Reset 后自动恢复 FRP 配置并重新连接 `frps`
- 每台设备根据 eth0 MAC 自动生成唯一 FRP Proxy Name
- SSH proxy 使用 `remote_port=0`，由 `frps` 分配可用端口，避免多设备端口冲突

业务程序（如 Shadowsocks）不固化到此 Recovery Image，后续通过远程控制链部署。

## 目录

```text
.
├── .github/workflows/
│   ├── build.yml
│   └── build-snapshot.yml
├── config/
│   ├── frpc.template
│   ├── packages.txt
│   └── packages-snapshot.txt
├── files/
│   └── etc/
│       └── uci-defaults/
│           └── 99-custom-init
├── scripts/
│   ├── build.sh
│   └── build-local.sh
└── dist/
```

## SNAPSHOT 预装包

`config/packages-snapshot.txt` 只额外加入：

```text
luci
frpc
```

其余保持 OpenWrt 对该 Profile 的默认软件集合。

## GitHub Actions 配置

在：

```text
Settings -> Secrets and variables -> Actions
```

配置：

- Repository variable `FRP_SERVER_ADDR`：frps 公网 IP 或域名
- Repository secret `FRP_TOKEN`：与 frps 一致的 Token

不要把真实 Token 提交到 Git。

## FRP 恢复逻辑

构建时 CI 根据 `config/frpc.template` 生成：

```text
/etc/config/frpc
/etc/frp/token
```

这两个文件进入 SquashFS，因此 Factory Reset 清空 overlay 后仍会恢复。

首次启动或 Factory Reset 后，`99-custom-init` 会：

1. 设置 hostname、时区和 LAN 管理地址。
2. 验证 `frpc`、FRP 配置和 Token 是否存在。
3. 读取 eth0 MAC，生成唯一设备 ID。
4. 将 FRP SSH proxy 名称设置为 `mt3600be-<device-id>-ssh`。
5. enable 并立即启动 `frpc`。
6. 如果 WAN 尚未就绪，frpc/procd 按配置自动重试。

FRP SSH proxy 使用 `remote_port=0`，适合多台同固件设备恢复时避免端口冲突。实际分配端口可从 frps 端查看。

## 构建

GitHub：

```text
Actions -> Build OpenWrt SNAPSHOT GL-MT3600BE -> Run workflow
```

主要输入：

- `firmware_version`
- `lan_ip`
- `hostname`

构建完成后下载 Artifact 中的：

```text
*gl-mt3600be*sysupgrade*.bin
```

## SNAPSHOT 部署原则

SNAPSHOT 是滚动版本。同一个 workflow 在不同日期重新构建，底层 OpenWrt revision 可能不同。

因此批量部署应遵循：

```text
构建一次
-> 单台验证 WAN / FRP / Factory Reset
-> 保存 sysupgrade.bin + SHA256
-> 同一批设备全部刷完全相同的 bin
```

不要为每台设备单独重新构建 Snapshot。
