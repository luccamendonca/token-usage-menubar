# Token Usage Menubar

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![GitHub release](https://img.shields.io/github/v/release/luccamendonca/token-usage-menubar?sort=semver&label=release)](https://github.com/luccamendonca/token-usage-menubar/releases)

Small **macOS menu bar** app (Swift / SwiftUI) that shows **Claude Code** OAuth usage: rolling **5-hour** and **7-day** windows with reset times. It uses the same local credential source as Claude Code (Keychain item `Claude Code-credentials`) and the undocumented `GET https://api.anthropic.com/api/oauth/usage` endpoint.

**Not affiliated with Anthropic.** See `NOTICE`.

**Menu bar title** looks like: `6% (short date/time) 35% (short date/time)` — the popover shows ISO8601 reset timestamps, **Refresh now**, and **Quit**.

## Prebuilt binary (Apple Silicon)

Published on [Releases](https://github.com/luccamendonca/token-usage-menubar/releases). Each tag `v*.*.*` builds a zip plus `SHA256` sidecar on **macOS arm64** (GitHub `macos-14` runners).

After download:

```bash
unzip token-usage-menubar-*-macos-arm64.zip
chmod +x token-usage-menubar
./token-usage-menubar
```

Keep the app running from **Login Items** or a launcher if you want it always available.

## Requirements

- macOS **13+**
- **Apple Silicon** for the CI-built binary (local `swift build` can target your machine)
- **Claude Code** signed in on that Mac so the Keychain entry exists

## Build from source

### Swift Package Manager

```bash
swift build -c release
swift run -c release
```

Release binary path (varies by toolchain; this resolves it):

```bash
"$(swift build -c release --show-bin-path)"/TokenUsageMenubar
```

Accessory activation policy is set in code so there is **no Dock icon** when running the bare executable.

Optional `.app` bundle:

```bash
APP=TokenUsageMenubar.app
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)"/TokenUsageMenubar "$APP/Contents/MacOS/"
cp ClaudeUsageToolbar/Info.plist "$APP/Contents/"
chmod +x "$APP/Contents/MacOS/TokenUsageMenubar"
open "$APP"
```

### Xcode

Open `ClaudeUsageToolbar.xcodeproj`, scheme **ClaudeUsageToolbar**, Run.  
Or: `xcodebuild -project ClaudeUsageToolbar.xcodeproj -target ClaudeUsageToolbar -configuration Release build` (requires full Xcode selected via `xcode-select`).

The app target is **not sandboxed** so it can invoke `/usr/bin/security` to read the same Keychain item Claude Code uses.

## Releases & versioning

- **Tags:** `vMAJOR.MINOR.PATCH` (started at **`v1.0.0`**).
- Pushing a matching tag runs [`.github/workflows/release.yml`](.github/workflows/release.yml), which uploads `token-usage-menubar-<version>-macos-arm64.zip` and a `.sha256` file to a GitHub Release.

## Behavior

- **5-hour window** (`five_hour.*`): short rolling limit (same family as Claude Code `/usage` UI), not a literal per-message session count.
- **7-day window** (`seven_day.*`): aggregate weekly bucket from the API.
- Polling every **120** seconds, plus launch + manual refresh.

## Privacy

Credentials are read only from your Mac’s Keychain; HTTP requests go to Anthropic’s API. Nothing is sent to third-party analytics by this app.

## License

Copyright © 2026 Lucca Mendonca. Licensed under **GNU General Public License v3.0** — see [`LICENSE`](LICENSE). Contributing implies acceptance of the same terms — see [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Disclaimer

Anthropic may change or remove private APIs at any time. This tool is for personal productivity; you are responsible for complying with Anthropic’s terms of service.
