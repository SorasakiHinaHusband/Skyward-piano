**简体中文** | [English](README.md)

# 小米平板 8 Pro（piano）的 Skyward

这是 [Skyward](https://github.com/kirklin/skyward) 0.3.1 在小米平板 8 Pro
（代号 `piano`，型号 `25091RP04C`，HyperOS 4 `OS4.0.6.0.XPYCNXM`）上的移植。
代码树同时包含
[shawude/skyward-oneplus13-sun](https://github.com/shawude/skyward-oneplus13-sun)
里的 OnePlus 兼容改动；Skyward 在非小米固件上需要这些改动。这里只附带
`piano` 一个设备的配置。

## 下载

镜像：[**v0.3.1 Release 附件**](https://github.com/SorasakiHinaHusband/Skyward-piano/releases/download/v0.3.1/skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img)

```text
SHA-256: 628c7715f274a3204f0ce54c231514c9f984b7bbda40f3283992e0ad28759f21
```

镜像约 100 MiB，所以作为 Release 附件提供，不直接提交进仓库。制作它所用的
原厂 recovery 也没有提交，见下文。

## 已验证

- 能从 recovery 分区启动，ADB root 正常。
- 显示模式为 `3200x2136x144vid`（**144 Hz**）。
- 横屏下触摸正常；**设置 → 屏幕方向**可切到竖屏再切回，触摸会跟着旋转后的
  画面走。
- 解密正常（`/data`、`/sdcard` 可挂载，界面显示“已解密”）。
- Wi-Fi 能连接并拿到 DHCP 地址。
- 电池图标和电量读数正常。
- 平板没有振动模块，设置页不显示振动栏目。

## 刷入

两个 recovery 槽位都刷：

```sh
fastboot flash recovery_a skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img
fastboot flash recovery_b skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img
fastboot reboot recovery
```

保留原厂 recovery 以便回滚：

```sh
fastboot flash recovery_a stock-piano-recovery.img
fastboot flash recovery_b stock-piano-recovery.img
```

## 构建

打包器会保留原厂内核，只把 recovery 的 ramdisk 换成 Skyward 的。原厂
`recovery.img` 要从对应的 HyperOS 4 全量包（`OS4.0.6.0.XPYCNXM`）里取；
`scripts/fetch-stock-piano.sh` 里是 OTA 下载/解包的做法。

```sh
export ANDROID_NDK_HOME=/path/to/android-ndk-r29
scripts/build.sh piano stock/piano/recovery.img out/skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img
```

`scripts/build.sh` 会依次构建 `skyward-pack`、Android 版 `skyward` 和静态
`system-init`，然后打包镜像。`skyward/target/` 不会提交进仓库。

## 配置

- `skyward/devices/piano.toml`：本仓库唯一的设备配置。
- `[display] orientation_switch = true`：打开设置里的横屏/竖屏切换。
- `[touch] swap_xy = true`、`invert_y = true`：把竖屏触摸面板映射到 DRM
  横屏模式；竖屏模式使用面板自身的坐标轴。
- `[wlan]` 使用 `peach_v2`，配置文件为
  `/vendor/etc/wifi/peach_v2/WCNSS_qcom_cfg.ini`。

## 目录

```text
skyward/              Skyward 0.3.1 源码 + 本移植的修改
  devices/piano.toml  设备配置
  crates/             Rust crates
docs/PORTING.md       改了什么、为什么
docs/TESTING.md       首次启动检查清单
patches/              相对上游 Skyward 0.3.1 的补丁
scripts/build.sh      构建 + 打包
scripts/fetch-stock-piano.sh
tools/ota-extract/    用来提取原厂 recovery 的 OTA payload 工具
```

## 修复 OTA 状态残留

OTA 完成后，如果目标槽已经启动、snapshots 也没了，但 Skyward 仍显示“更新
已写入，等待合并”，通常是 libsnapshot 的 `/metadata/ota/state` 还停在
`Initiated`/`Unverified`（例如手动 `fastboot --set-active` 后）。可以这样修：

```sh
adb shell /system/bin/recovery vab-repair --force
```

命令会先把原文件备份成 `state.before`，只有状态确实是“已写入”时才改；
真正在合并或合并失败时不会动。请确认目标槽已经启动过再执行。

## 已知限制

- 面板原生是竖屏，而 DRM 模式是横屏，所以必须用上面的触摸变换。如果左右反了，
  加 `invert_x = true`；如果上下反了，去掉 `invert_y`。
- 切换屏幕方向会重启 recovery 来应用新布局。
- 平板没有振动模块，设置页不显示振动栏目。
- 原厂 recovery 底包要匹配 `OS4.0.6.0.XPYCNXM`（或兼容的 HyperOS 4）；
  换底包可能需要新的 `[stock]` 配置。

## 许可证

GPL-3.0-or-later，与上游 Skyward 一致。见 `skyward/LICENSE`。
