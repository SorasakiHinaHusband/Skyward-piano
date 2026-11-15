# 首次测试清单 — piano

> 以下操作只写 recovery 分区，不会清 data。请确认 bootloader 已解锁，并保留
> 原厂 recovery 以便回滚。

## 刷入

```sh
sha256sum skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img
fastboot flash recovery_a skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img
fastboot flash recovery_b skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img
fastboot reboot recovery
```

首次启动可能需要 30–60 秒（等 data 解密和 key 服务）。

## 检查项

按顺序测，哪一步失败就停在那里：

1. **显示**：首页应正常亮度、无花屏。面板原生竖屏，但 Skyward 以
   `3200x2136x144vid`（144 Hz）横屏模式运行；`dmesg | grep 'skyward: display'`
   应看到 144 Hz。
2. **触摸**：点按、滑动应落在手指位置。配置为 `[touch] swap_xy = true`、
   `invert_y = true`；若左右反了加 `invert_x = true`，若上下反了去掉
   `invert_y`。
3. **横竖屏切换**：设置 → 屏幕方向，选竖屏后 recovery 会自动重启；竖屏画面
   应正向，触摸仍准确。再切回横屏确认。
4. **adb**：`adb devices` 应看到设备；`adb shell id` 应为 `uid=0(root)`。
5. **data 解密**：如果设置了锁屏密码，在解密页输入；`/data`、`/sdcard`
   应可读写，设置页显示“已解密”。
6. **Wi-Fi**：打开 WLAN 页面扫描并连接，`ifconfig wlan0` 应拿到地址。
7. **电池**：状态栏应有电池图标和百分比。
8. **重启**：`重启到系统` 应回到已安装系统；再 `adb reboot recovery` 应回到
   Skyward。

## 出问题时

```sh
adb shell dmesg | grep 'skyward:'
adb shell logcat -d | tail -200
```

保留 `stock-piano-recovery.img`，需要时刷回两个 recovery 槽位。
