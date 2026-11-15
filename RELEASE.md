# Skyward 0.3.1 — Xiaomi Pad 8 Pro (piano)

Image for the Xiaomi Pad 8 Pro on HyperOS 4 `OS4.0.6.0.XPYCNXM`.

| Image | SHA-256 |
| --- | --- |
| `skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img` | `628c7715f274a3204f0ce54c231514c9f984b7bbda40f3283992e0ad28759f21` |

Flash both recovery slots:

```sh
fastboot flash recovery_a skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img
fastboot flash recovery_b skyward-0.3.1-piano-OS4.0.6.0.XPYCNXM.img
fastboot reboot recovery
```

Verified on the tablet: 144 Hz display, touch, portrait/landscape switch,
decryption, Wi-Fi and battery. See `README.md` and `docs/PORTING.md`.
