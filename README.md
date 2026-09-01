# Headroom

A native macOS menu bar extra that shows how much [Oh My Pi](https://github.com/can1357/oh-my-pi) usage you have left, per provider, at a glance.

Headroom shells `omp usage --json` on a schedule and renders the result as a status item plus popover. No browser, no Electron, no resident `omp` process — one small SwiftUI app.

## What it shows

- Every authenticated provider, grouped, sorted so the tightest budget is on top
- Remaining percent per usage window and model tier
- Reset times ("resets in 2h 10m") and snapshot age
- The menu bar mark tracks your tightest window, so a glance tells you whether you are about to hit a limit

## Requirements

- macOS 14 or newer
- Xcode command line tools with a Swift 6.2 toolchain
- [Oh My Pi](https://github.com/can1357/oh-my-pi) installed with providers already logged in

## Install

```sh
git clone https://github.com/johnway114/headroom.git
cd headroom
make install
open ~/Applications/Headroom.app
```

`make install` builds a release binary and assembles `Headroom.app` in `~/Applications`. The extra appears as a template portal mark in the menu bar; click it for the usage popover. Refresh, Open at login, and Quit live in the popover footer.

If a menu bar manager (Hidden Bar, Bartender) swallows the extra, drag the mark out of the hidden section.

## Configuration

`omp` is resolved from `~/.local/bin/omp`, Homebrew, or a login shell `PATH`. Point Headroom at a specific binary with:

```sh
defaults write com.johnconway.headroom ompPath /path/to/omp
```

## Development

```sh
make test      # swift test
make install   # release .app into ~/Applications
make uninstall
```

The package splits into `HeadroomCore` (decoding and formatting of `omp usage --json`, unit tested against a fixture) and `Headroom` (the menu extra app).

## License

MIT — see [LICENSE](LICENSE).
