# LispGB

**English** | [日本語](README.ja.md)

A Game Boy / Game Boy Color emulator written in Common Lisp (SBCL), with SDL2 for video, audio, and input. It runs from the command line and does not require a boot ROM.

## Status

LispGB is experimental. It supports DMG and CGB graphics, four-channel stereo audio, MBC1/2/3/5, battery saves, and save states. The Blargg CPU/audio and acid2 tests pass; three Mooneye timing edge cases remain known failures. Please keep backups of valuable save files.

The emulation core is based on [RuxBoy](https://github.com/bubio/ruxboy), whose core originated in BubiBoy Lite.

## Supported platform

Linux amd64 / arm64, targeting Ubuntu 24.04 or newer. Both architectures have been verified locally and in CI. Release builds use Ubuntu 24.04.

macOS Apple Silicon and Intel: separate native builds are produced by macOS CI. ZIP files are named `macos-arm64` (Apple Silicon) and `macos-amd64` (Intel). Local GUI operation has been verified on Apple Silicon; Intel GUI operation has not been verified.

## Installation

Extract the distribution ZIP and install the SDL2 runtime:

```sh
sudo apt install libsdl2-2.0-0
./lispgb --version
```

On macOS, install SDL2 with Homebrew before running the extracted executable:

```sh
brew install sdl2
./lispgb --version
```

Keep the executable and any included `.dylib` files in the same directory.

SBCL is not needed to run the executable. SDL2 is not needed for headless operation, help, version, or the recent-ROM list.

## Building from source

```sh
sudo apt install sbcl libsdl2-dev
sh scripts/build.sh
./build/lispgb --version
```

On macOS:

```sh
brew install sbcl sdl2
sh scripts/build.sh
./build/lispgb --version
```

No Quicklisp packages are required.

## Usage

```text
lispgb [options] game.gbc

  -h, --help          Show usage
  -v, --version       Show version
  --scale N           Display scale, 1–8 (default 4; larger values become 8)
  --fullscreen        Fullscreen display
  --shader KIND       nearest or smooth (default nearest)
  --recent            List recently used ROMs
  --headless          Run without video or audio devices
  --frames N          Number of headless frames (required with --headless)
  --screenshot PATH   Save the final headless frame as a BMP
```

```sh
./lispgb --scale 4 game.gbc
./lispgb --headless --frames 120 --screenshot frame.bmp game.gbc
```

### Keyboard shortcuts

| Key | Function |
|---|---|
| Arrow keys | D-pad |
| Z / X | B / A |
| Enter | Start |
| Right Shift | Select |
| F1 | Save state |
| F3 | Load state |
| Esc | Quit |

Battery saves use `<ROM name>.sav`; states use `<ROM name>.state`, alongside the ROM. A save with an unexpected size is moved to `.sav.bak` before a new save is written. An existing backup is preserved. States from a different ROM are rejected.

### Configuration

On first launch, LispGB creates `$XDG_CONFIG_HOME/LispGB/config.txt`, or `~/.config/LispGB/config.txt` when the environment variable is unset or empty:

```text
scale = 4
fullscreen = false
shader = nearest
volume = 100
```

On macOS, configuration and recent ROMs are stored in `~/Library/Application Support/LispGB/`, regardless of `XDG_CONFIG_HOME`.

Volume ranges from 0 to 100. Command-line options override configuration values. `#` starts a comment. Invalid entries are ignored. `recent.txt` in the same directory stores up to ten recent ROM paths.

## License

MIT. See [LICENSE](LICENSE).
