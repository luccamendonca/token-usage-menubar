# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-04-08

### Added

- macOS menu bar app showing Claude Code OAuth usage (`five_hour` / `seven_day` windows).
- SwiftPM build (`swift build` / `swift run`) and optional Xcode project (`.xcodeproj`).
- Keychain-based credential read (`Claude Code-credentials`) and `GET /api/oauth/usage` client.
- GitHub Actions release workflow producing a signed-checksum zip for Apple Silicon.

[1.0.0]: https://github.com/luccamendonca/token-usage-menubar/releases/tag/v1.0.0
