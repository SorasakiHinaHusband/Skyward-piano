# Port notes

## Base and provenance

The tree in [`skyward/`](../skyward) is Skyward **0.3.1**
(`kirklin/skyward`, GPL-3.0-or-later) with the OnePlus compatibility work
from `shawude/skyward-oneplus13-sun` (also GPL-3.0-or-later). That work is
what lets a non-Xiaomi device boot at all:

| File | What the OnePlus work changes |
| --- | --- |
| `crates/skyward-pack/src/main.rs` | rewrites OnePlus's `start phoenix_recovery` to `start recovery` in the stock `init.rc`, and disables `phoenix_recovery` so `class_start default` does not start it beside Skyward |
| `crates/skyward-modules/src/lib.rs` | resolves `modules.dep` dependencies across `vendor_boot`, `vendor_dlkm`, `vendor` and `system_dlkm`, and accepts OnePlus's `system_dlkm/lib/modules` layout |
| `crates/skyward-config/src/lib.rs` | adds `[device] mtp`, `[wlan] unblock`, `[haptics] period` and `[device] permissive` |
| `crates/skyward/src/main.rs` | writes `/sys/fs/selinux/enforce=0` when `permissive` is set, before the installed system's APEX bundles are mounted |
| `crates/skyward/src/main.rs` | asks for `adb` without first taking USB through `none`; closes `/data` before reboot |
| `crates/skyward/src/ui.rs` | tolerates a panel with no backlight node; gates file transfer on `mtp`; closes `/data` before powering off |
| `crates/skyward/src/wlan.rs` | waits 45 s for the interface, tolerates late sysfs switches, unblocks rfkill through `soft` (OnePlus's `state` is the inverse) |
| `crates/skyward/src/input.rs` | `[touch] swap_xy`, `invert_x` and `invert_y`: maps a panel whose axes differ from the display mode; portrait uses the panel's own axes; every tap emits the motor's click when touch vibration is on |
| `crates/skyward-ui/src/surface.rs` | rotates a portrait canvas a quarter counter-clockwise into a landscape KMS buffer; picks the fastest mode by the refresh in its name when the kernel reports 0 |
| `crates/skyward-ui/src/{app/state.rs,app/prefs.rs,app/act.rs,pages.rs,settings.rs}` | `portrait` state/setting, the orientation row, and the restart-to-apply effect |
| `crates/skyward-programs/src/secure.rs` | recognizes Xiaomi's generic `android.hardware.weaver` as a weaver that reaches the secure world directly (`Through::Direct`) |
| `crates/skyward-net/src/iface.rs` | treats an interface that is already up as success, instead of failing with `EBUSY` on the second bring-up |
| `crates/skyward/src/haptics.rs` | derives the motor frequency from `t_lra_us` when `lra_frequency_hz` reads 0 |
| `crates/skyward-crypto/src/data.rs` | detaches busy mounts and tolerates a missing dm device when closing data |
| `crates/skyward-programs/src/script.rs` | accepts `//` and `/* */` comments used by vendor init scripts |
| `crates/skyward-programs/src/phone.rs` | skips an init script init itself would reject |
| `crates/skyward-programs/src/secure.rs` | recognizes OnePlus's NXP weaver name (`.nxp`) |

No further C++/Rust changes were needed: all remaining differences are in
`devices/piano.toml`.

## Xiaomi Pad 8 Pro (`piano`)

Stock baseline: HyperOS 4 China `OS4.0.6.0.XPYCNXM`
(`piano-ota_full-OS4.0.6.0.XPYCNXM-user-17.0-96dbee09b8.zip`).
Model `25091RP04C`. A/B, 100 MiB recovery partition (104857600 bytes),
header v4, LZ4 ramdisk, kernel supplied by the active `boot` partition.

| Item | Value used | Source |
| --- | --- | --- |
| Panel | 2136 × 3200, 440 dpi, LCD, 11.2″ | device tree `TARGET_SCREEN_DENSITY := 440`, touch firmware `display_x_resolution=2136` / `display_y_resolution=3200` |
| Panel rotation | 270° in the stock system | `ro.surface_flinger.primary_display_orientation=ORIENTATION_270` |
| Touch | Novatek NT36532 + `xiaomi_touch` | recovery tree `TW_LOAD_VENDOR_MODULES`, `vendor_dlkm/modules.load` |
| Touch processing | `/odm/bin/touch_report_debug` (same 4208-byte launcher TWRP ships as `touch_report`, loads `libtouchreport.so`) | stock ODM, byte-identical to the TWRP tree's file |
| Touch axes | panel grid is portrait while the DRM mode is landscape: `[touch] swap_xy = true`, `invert_y = true` | TWRP's `RECOVERY_TOUCHSCREEN_SWAP_XY` + `FLIP_Y` for piano |
| Orientation | settings row switches landscape/portrait; portrait turns the canvas a quarter counter-clockwise and uses the touch grid directly | tested on the tablet |
| WLAN | QCA `qca_cld3_peach_v2` | `ro.hardware.wlan.chip=qca_cld3_peach_v2` |
| WLAN firmware | `/vendor/firmware/wlan/qca_cld/peach_v2` links to vendor cfg and persist MAC | stock vendor image |
| Secure element | ST54L; no `st,st54spi_gpio` node in any `sun*.dtb`, so the `stm_st54se_gpio` driver and its `/dev/st54spi_gpio` owner were deliberately left out | DTBs and vendor modules |
| Haptics | none configured | TWRP tree sets `TW_NO_HAPTICS := true` |

Configuration choices:

- `[modules] load = ["xiaomi_touch", "nt36532_touch"]`; the stock recovery
  already loads the ADSP modules in `init.recovery.qcom.rc`.
- `[[service]] /odm/bin/touch_report_debug` with
  `LD_LIBRARY_PATH=/odm/lib64:/vendor/lib64:/system/lib64`, `root` in
  `root,uhid,input`, capability `SYS_NICE`.
- `[touch] swap_xy = true`, `invert_y = true`; the first boot drew the
  landscape UI but mapped touches as if the panel were portrait, so the
  transform was added after the first test (the TWRP tree carries the same
  two flags).
- `[display] orientation_switch = true` adds **Settings → 屏幕方向**. The
  choice is kept in `/metadata/skyward/settings.json`; Skyward restarts the
  recovery through init, and on the next start the pages use the swapped
  dimensions and `KmsSurface::present` turns the frame a quarter
  counter-clockwise. Touch uses the panel's own axes in portrait.
- `[[service]] /vendor/bin/init.kernel.post_boot.sh` as a oneshot root
  service, so the CPU clusters leave the performance governor.
- `[firmware] partition = "modem"` and `[partitions] mounted = ["persist"]`;
  the WLAN driver reads its settings and MAC through the vendor firmware
  links.
- `[wlan]` uses peach_v2, `fs_ready`, the Xiaomi probe URL, and an explicit
  `firmware` entry for `/vendor/etc/wifi/peach_v2/WCNSS_qcom_cfg.ini`. The
  vendor partition's `/vendor/firmware/wlan/qca_cld/peach_v2` links are
  hidden once the stock recovery binds the modem image over
  `/vendor/firmware`, so the config is placed where the loader looks. A
  persist MAC entry was tried and removed: persist is already mounted, and
  mounting it a second time made the WLAN bring-up fail with `EBUSY`; the
  driver uses its default MAC.
- No `[haptics]`, no `[touch] writes`: the panel's driver reports raw
  frames and `touch_report_debug` turns them into touches, as TWRP does.

Stock recovery used: `stock/piano/recovery.img`,
SHA-256 `19e676d7c1914688f3289df49b2e3a9e705901a300f595733634189e8508ca8f`.

## How the image was built

```sh
export ANDROID_NDK_HOME=.../android-ndk-r29
cargo build --release -p skyward-pack
cargo build --release --target aarch64-linux-android -p skyward
RUSTFLAGS="-C target-feature=+crt-static" \
  cargo build --release --target aarch64-linux-android \
  -p skyward-system-init --target-dir target/system-init

skyward/target/release/skyward-pack recovery \
  --stock stock/piano/recovery.img \
  --binary skyward/target/aarch64-linux-android/release/skyward \
  --system-init skyward/target/system-init/aarch64-linux-android/release/system-init \
  --config skyward/devices/piano.toml \
  --font skyward/resources/fonts/MiSansVF.ttf \
  --mono skyward/resources/fonts/KirkMono-Regular.ttf \
  --mono-license skyward/resources/fonts/KirkMono-OFL.txt \
  --out out/skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img
```

Or run `scripts/build.sh piano stock/piano/recovery.img <output>` after
putting the stock recovery in `stock/piano/`.

## Verification status

- The image passes `skyward-pack list` and embeds its TOML byte for byte.
- Booted on the tablet: partitions mount, ADB root comes up, the UI draws
  in landscape at `3200x2136x144vid` (144 Hz), and `/data` and `/sdcard`
  mount with the UI showing `已解密`.
- Touch works in both orientations; **Settings → 屏幕方向** restarts the
  recovery and applies the chosen layout.
- Wi-Fi gets a DHCP address; the battery icon and readings work.
- The stock recovery used as the base is not committed; get it from the
  `OS4.0.6.0.XPYCNXM` full OTA.
