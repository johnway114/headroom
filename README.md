# Headroom

Native macOS menu extra for remaining OMP usage.

It shells `omp usage --json` and shows each authenticated provider, broken down by window and model tier. No browser, no resident `omp` process.

Requires [Oh My Pi](https://github.com/can1357/oh-my-pi) with accounts already logged in.

## Install

```sh
cd ~/Documents/headroom
make install
open ~/Applications/Headroom.app
```

The extra is a template portal mark. Click it for remaining percent and reset times. Refresh, Open at login, and Quit are in the popover footer.

If Hidden Bar swallows the extra, expand the chevron and drag the mark to the right of the separator.

## Commands

```sh
make test      # swift test
make install   # release .app into ~/Applications
make uninstall
```

`omp` is resolved from `~/.local/bin/omp`, Homebrew, or a login shell `PATH`. Override with `defaults write com.johnconway.headroom ompPath /path/to/omp`.
