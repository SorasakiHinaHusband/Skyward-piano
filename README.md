**English** | [简体中文](README.zh-CN.md)

# Skyward for Xiaomi Pad 8 Pro (piano)

A port of [Skyward](https://github.com/kirklin/skyward) 0.3.1 to the Xiaomi
Pad 8 Pro (`piano`, model `25091RP04C`) on HyperOS 4
`OS4.0.6.0.XPYCNXM`. The tree also carries the OnePlus compatibility work
from [shawude/skyward-oneplus13-sun](https://github.com/shawude/skyward-oneplus13-sun)
that Skyward needs on non-Xiaomi firmware; only the `piano` device
configuration is shipped here.

## Download

Image: [**v0.3.1 release asset**](https://github.com/SorasakiHinaHusband/Skyward-piano/releases/download/v0.3.1/skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img)

```text
SHA-256: d29a3da1b0c657464a0eac02e14c247dc7e88ddfbccff0f150b8384b97c35974
```

The image is a release asset rather than a committed file because it is
about 100 MiB. The stock recovery used as its base is not committed; see
below.

## Verified on the tablet

- Boots from the recovery partition, ADB root comes up.
- Display runs at `3200x2136x144vid` (**144 Hz**).
- Touch works in landscape; **Settings → 屏幕方向** switches to portrait and
  back, and touch follows the rotated page.
- Decryption works (`/data`, `/sdcard` mount; the UI shows `已解密`).
- Wi-Fi associates and gets a DHCP address.
- Battery icon and readings work.

## Flashing

Both recovery slots:

```sh
fastboot flash recovery_a skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img
fastboot flash recovery_b skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img
fastboot reboot recovery
```

Keep the stock recovery for rollback:

```sh
fastboot flash recovery_a stock-piano-recovery.img
fastboot flash recovery_b stock-piano-recovery.img
```

## Building

The packer replaces the stock recovery's ramdisk with Skyward's and keeps
the stock kernel. Get the stock `recovery.img` from the matching HyperOS 4
full OTA (`OS4.0.6.0.XPYCNXM`); `scripts/fetch-stock-piano.sh` shows the
OTA download/extract route.

```sh
export ANDROID_NDK_HOME=/path/to/android-ndk-r29
scripts/build.sh piano stock/piano/recovery.img out/skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img
```

`scripts/build.sh` builds `skyward-pack`, the Android `skyward` binary and
the static `system-init`, then packs the image. `skyward/target/` is not
tracked.

## Configuration

- `skyward/devices/piano.toml` — the only device file in this tree.
- `[display] orientation_switch = true` enables the portrait/landscape row.
- `[touch] swap_xy = true`, `invert_y = true` map the portrait touch panel
  to the DRM landscape mode; portrait mode uses the panel's own axes.
- `[wlan]` uses `peach_v2` and the vendor config at
  `/vendor/etc/wifi/peach_v2/WCNSS_qcom_cfg.ini`.

## Layout

```text
skyward/              Skyward 0.3.1 source + this port's changes
  devices/piano.toml  device configuration
  crates/             Rust crates
docs/PORTING.md       what was changed and why
docs/TESTING.md       first-boot checklist
patches/              the port as a patch against upstream Skyward 0.3.1
scripts/build.sh      build + pack
scripts/fetch-stock-piano.sh
tools/ota-extract/    OTA payload extractor used to get the stock recovery
```

## Repairing a stale OTA state

After an OTA, Skyward can still say "Update written, waiting to merge" when
the target slot has already booted and its snapshots are gone but
libsnapshot's state file was left at `Initiated`/`Unverified` (for example
after a manual `fastboot --set-active`). Repair it with:

```sh
adb shell /system/bin/recovery vab-repair --force
```

The command backs up `/metadata/ota/state` as `state.before`, refuses while
a merge is really running or failed, and marks the update merged. Use it
only after the target slot has started.

## Known limitations

- The panel's native grid is portrait while the DRM mode is landscape; the
  touch transform above is required. If left/right is reversed add
  `invert_x = true`; if up/down is reversed remove `invert_y`.
- Changing orientation restarts the recovery to apply the new layout.
- Haptics are not configured on this tablet.
- The stock recovery base must match `OS4.0.6.0.XPYCNXM` (or a compatible
  HyperOS 4 build); a different base may need a new `[stock]` block.

## License

GPL-3.0-or-later, as upstream Skyward. See `skyward/LICENSE`.
