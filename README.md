<div align="center">

# NiMiFy

**Fork of [Hiddify](https://github.com/hiddify/hiddify-app) — Windows-focused build**

بر پایه Hiddify؛ بهینه‌شده برای ویندوز با نام، بسته‌بندی، مسیرهای به‌روزرسانی و بیلد CI اختصاصی.

</div>

## What is this?

A multi-platform proxy client based on [Sing-box](https://github.com/SagerNet/sing-box), forked from [hiddify/hiddify-app](https://github.com/hiddify/hiddify-app) and customized:

- ✅ Windows branding: `NiMiFy` (separate install dir, app identity, registry keys, mutex — no clash with an existing Hiddify install; both can coexist)
- ✅ Windows-only build pipeline: fork's GitHub Actions builds only the Windows targets (exe installer / portable zip), no Android/iOS/macOS jobs, no store releases
- ✅ All update/appcast/release URLs point at this fork — updates come from `Nim4a/NiMiFy` releases
- ✅ Simplified `make windows-libs`: downloads core with retry into `hiddify-core/bin/` (robust on flaky links)
- ✅ Upstream bug-fix base: forked at commit `276a7ef` (v4.1.2 line)

## Protocols

VLESS, VMess, Reality, TUIC, Hysteria, Hysteria2, Shadowsocks, Trojan, WireGuard, SSH — via the Sing-box core. Subscription formats: Sing-box, V2ray, Clash, Clash Meta.

## Windows download

Get the installer from [Releases](https://github.com/Nim4a/NiMiFy/releases):

- `NiMiFy-Windows-Setup-x64.exe` — Inno Setup installer
- `NiMiFy-Windows-Portable-x64.zip` — portable, no install
- `NiMiFy-Windows-x64.msix` — MSIX (unsigned build; enable sideloading or install the provided cert)

## Build from source (Windows)

```bash
git clone https://github.com/Nim4a/NiMiFy.git
cd hiddify-app
make windows-prepare   # pub get, build_runner, slang, downloads core libs
make windows-release   # zip + exe + msix via fastforge
```

Requirements: Flutter 3.38.x stable, Inno Setup 6 (for the exe target), `dart pub global activate fastforge`.

CI: pushing to `main` runs [Build](.github/workflows/build.yml) and uploads artifacts to the `draft` prerelease; tag `vX.Y.Z` publishes a release.

## Keeping in sync with upstream

```bash
git remote add upstream https://github.com/hiddify/hiddify-app.git  # once
git fetch upstream
git checkout main
git merge upstream/main   # resolve conflicts, keeping fork branding files:
                          # lib/core/model/constants.dart, windows/* branding, packaging configs
git push
```

## Credits & license

All credit to the [Hiddify](https://github.com/hiddify/hiddify-app) team and contributors — see [LICENSE.md](LICENSE.md) (upstream license, inherited). This fork modifies branding, build pipeline and update endpoints only.

<div align="center">

*Fork maintained by [Nim4a](https://github.com/Nim4a)*

</div>
