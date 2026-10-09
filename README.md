# LispGB

**English** | [日本語](README.ja.md)

A Game Boy / Game Boy Color emulator written in Common Lisp (SBCL). It is a command-line application using SDL2 for video, audio, and input. No boot ROM is required.

This project began as a practical experiment to evaluate the usefulness of [Spec Kit](https://github.com/github/spec-kit).

The core is based on [RuxBoy](https://github.com/bubio/ruxboy), whose core originated in BubiBoy Lite (MIT License).

[![Release](https://img.shields.io/github/v/release/bubio/LispGB)](https://github.com/bubio/LispGB/releases/latest)
[![CI Linux](https://github.com/bubio/LispGB/actions/workflows/ci-linux.yml/badge.svg)](https://github.com/bubio/LispGB/actions/workflows/ci-linux.yml)
[![CI macOS](https://github.com/bubio/LispGB/actions/workflows/ci-macos.yml/badge.svg)](https://github.com/bubio/LispGB/actions/workflows/ci-macos.yml)
[![CI Windows](https://github.com/bubio/LispGB/actions/workflows/ci-windows.yml/badge.svg)](https://github.com/bubio/LispGB/actions/workflows/ci-windows.yml)
[![License](https://img.shields.io/github/license/bubio/LispGB)](LICENSE)

## Features

- Game Boy (DMG) and Game Boy Color (CGB) graphics, with four-channel stereo audio
- MBC1 / MBC2 / MBC3 (RTC) / MBC5
- Battery saves and save states using F1 / F3
- Display scaling, fullscreen, nearest / smooth filtering, configuration, and recent ROMs
- Headless execution without video or audio devices, and BMP screenshots

The Blargg CPU/audio and dmg-acid2 / cgb-acid2 tests pass. Three Mooneye timing edge cases remain known failures: `rapid_toggle`, `reti_timing`, and `stat_lyc_onoff`.

## Supported platforms

| Platform | ZIP to download |
|---|---|
| Ubuntu 24.04 or newer (amd64 / x86_64) | `LispGB-1.0.0-linux-amd64.zip` |
| Ubuntu 24.04 or newer (arm64 / aarch64) | `LispGB-1.0.0-linux-arm64.zip` |
| macOS (Apple Silicon) | `LispGB-1.0.0-macos-arm64.zip` |
| macOS (Intel) | `LispGB-1.0.0-macos-amd64.zip` |
| Windows 11 (x64) | `LispGB-1.0.0-windows-amd64.zip` |

GUI operation on Intel Macs has not been verified.

## Installation

Download the ZIP for your platform from [Releases](https://github.com/bubio/LispGB/releases) and extract it. SBCL and Quicklisp are not required to run it. ROMs are not included.

### Linux

Install the SDL2 runtime, then run from the extracted directory:

```sh
sudo apt install libsdl2-2.0-0
./lispgb game.gbc
```

### macOS

Install SDL2 with Homebrew or MacPorts, then run from the extracted directory. Keep the executable and the included `.dylib` files together.

```sh
brew install sdl2
# or: sudo port install libsdl2
./lispgb game.gbc
```

### Windows

The ZIP includes SDL2.dll. Keep it beside `lispgb.exe` and run from PowerShell:

```powershell
.\lispgb.exe game.gbc
```

Headless execution, `--help`, `--version`, and `--recent` do not load SDL2.

## Building from source

Clone the repository and enter its directory. No external Lisp packages or submodules are required.

```sh
git clone https://github.com/bubio/LispGB.git
cd LispGB
```

### Linux (Ubuntu 24.04 or newer)

```sh
sudo apt install sbcl libsdl2-dev
sh scripts/build.sh
./build/lispgb game.gbc
```

### macOS

```sh
brew install sbcl sdl2
# or: sudo port install sbcl libsdl2
sh scripts/build.sh
./build/lispgb game.gbc
```

### Windows

Install x64 SBCL and add `sbcl` to PATH, then run in PowerShell. Downloading SDL2 requires an internet connection.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build.ps1
powershell -ExecutionPolicy Bypass -File scripts/fetch_sdl2.ps1
.\build\lispgb.exe game.gbc
```

The executable is generated at `build/lispgb` on Linux / macOS, or `build/lispgb.exe` on Windows.

## Usage

```text
lispgb [options] <ROM file>

  -h, --help          Show usage
  -v, --version       Show version
  --scale N           Display scale, 1–8 (default 4; larger values become 8)
  --fullscreen        Fullscreen display (--scale is ignored)
  --shader KIND       nearest or smooth (default nearest)
  --recent            List recently used ROMs and exit
  --headless          Run without video or audio devices
  --frames N          Number of headless frames (required with --headless)
  --screenshot PATH   Save the final frame as a BMP
```

```sh
./lispgb --scale 2 --shader smooth game.gbc
./lispgb --headless --frames 120 --screenshot frame.bmp game.gbc
```

On Windows, use `.\lispgb.exe` instead of `./lispgb`.

### Keyboard shortcuts (while a ROM is running)

| Key | Function |
|---|---|
| Arrow keys | D-pad |
| Z / X | B / A |
| Enter | Start |
| Right Shift | Select |
| F1 | Save state |
| F3 | Load state |
| Esc | Quit |

### Saves

Battery saves use `<ROM name>.sav`; save states use `<ROM name>.state`, alongside the ROM. There is one save-state slot. Invalid states and states from a different ROM are rejected.

A battery save with an unexpected size is moved to `.sav.bak`; existing backups are preserved. Keep backups of valuable saves. RTC time elapsed while the emulator is closed is not saved.

### Configuration

On first launch, LispGB creates `config.txt` in the following directory. `recent.txt` in the same directory stores up to ten recent ROM paths.

| OS | Directory |
|---|---|
| Linux | `$XDG_CONFIG_HOME/LispGB/`, or `~/.config/LispGB/` when unset or empty |
| macOS | `~/Library/Application Support/LispGB/` |
| Windows | `%APPDATA%\LispGB\` |

```text
scale = 4
fullscreen = false
shader = nearest
volume = 100
```

Volume ranges from 0 to 100. Command-line options override configuration values. `#` starts a comment. Invalid entries are ignored.

## License

[MIT License](LICENSE)
