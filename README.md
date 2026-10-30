<p align="center">
  <img src="assets/pildot.png" alt="Pildot logo: a dot with a green-to-red battery gradient" width="160" height="160">
</p>

<h1 align="center">Pildot</h1>

<p align="center"><strong>Your battery, in a dot.</strong><br>A small macOS menu bar app that keeps your battery status in sight.</p>

<p align="center">
  <a href="https://github.com/rjn28/pildot/actions/workflows/ci.yml"><img src="https://github.com/rjn28/pildot/actions/workflows/ci.yml/badge.svg" alt="macOS checks"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license"></a>
</p>

Pildot pairs the day of the month with a colored battery dot in your menu bar. It stays out of the way, with no main window and no Dock icon.

This is a personal project shared as source code for anyone interested in how it works, adapting it, or building it for their own Mac. There are no prebuilt app downloads or installer releases.

## Features

- A compact day number and battery indicator in the menu bar.
- A smooth color range from red to green as the charge increases.
- A blinking dot at 15% or lower, only while running on battery.
- Battery percentage and power status available with a click.
- Optional launch at login, controlled from **Settings → Launch at Login**.
- Native Swift, AppKit, and IOKit, with no external dependencies, network requests, or analytics.

## Build and use

You need macOS 13 or later and Swift 6.0 or later, provided by a compatible Xcode or Command Line Tools installation. Check your toolchain with `swift --version`.

```bash
git clone https://github.com/rjn28/pildot.git
cd pildot
./script/build_app_bundle.sh release
```

Move the generated `Pildot.app` to `/Applications`, then open it. Click its menu bar indicator to view battery details, change the launch setting, or quit.

Enable **Launch at Login** after moving the app: the login registration uses its location on disk. Builds target the Mac's current architecture (Apple Silicon or Intel); they are not universal binaries.

When replacing an existing installation, disable its launch at login setting and quit it first. Re-enable the setting from the new app after moving it into place.

## Development

```bash
swift build
swift test
./script/build_and_run.sh --verify
```

The last command builds a Debug app bundle, restarts Pildot, and checks that its process is running. It requires a graphical macOS session. The script also supports `--debug` for LLDB and `--logs` for process logs.

Tests cover battery states, the color palette, icon rendering, and login registration using a simulated launch controller. GitHub Actions runs the build, tests, shell syntax checks, and Release bundle creation for pushes and pull requests. It does not publish binaries.

| Path | Purpose |
| --- | --- |
| `Sources/Pildot/` | App lifecycle, battery monitoring, menu bar rendering, and login settings |
| `Tests/PildotTests/` | Automated tests |
| `assets/` | App icon |
| `script/` | Local build and run tools |
| `package.sh` | Optional local installer creation |

See [CONTRIBUTING.md](CONTRIBUTING.md) for bug reports and pull requests.

## Optional local installer

```bash
./package.sh
```

This creates `Pildot.app` and `Pildot.dmg` locally. Set `PILDOT_DMG_PATH` to choose a different disk image destination. Generated apps and disk images are ignored by Git.

## Local behavior

Pildot reads battery status every 30 seconds. The animation timer runs only when the battery is at or below the critical threshold and is discharging.

Launch at login creates `~/Library/LaunchAgents/com.rjn28.Pildot.login.plist`. The app calls `launchctl` only when you enable or disable that setting.

## Uninstall

1. Disable **Settings → Launch at Login** in Pildot.
2. Quit Pildot from its menu.
3. Move `Pildot.app` to the Trash.

If you already removed the app, remove its login registration with:

```bash
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.rjn28.Pildot.login.plist"
rm -f "$HOME/Library/LaunchAgents/com.rjn28.Pildot.login.plist"
```

`bootout` may report that the service is not loaded if it was already disabled.

## License

Pildot is available under the [MIT license](LICENSE).
