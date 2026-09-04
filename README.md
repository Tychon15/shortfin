# shortfin

A Hyprland desktop built around a [Quickshell](https://quickshell.org/) shell
of the same name. The wallpaper picks the colours — bar, terminal, prompt,
notifications, window borders, GTK and Qt all follow whatever picture is on
the desktop.

```
     _____ __               __  _____
    / ___// /_  ____  _____/ /_/ __(_)___
    \__ \/ __ \/ __ \/ ___/ __/ /_/ / __ \
   ___/ / / / / /_/ / /  / /_/ __/ / / / /
  /____/_/ /_/\____/_/   \__/_/ /_/_/ /_/
```

## What is in here

**The shell** (`config/quickshell/shortfin/`) — a top bar with workspaces,
special-workspace indicator, focused window, clock, system tray, volume,
brightness, network, battery and a session menu. Plus:

- an **application launcher** on Super, ranked by how often you launch things
- a **utility panel** that rises from the bottom edge of the screen, with
  media controls and synced lyrics, live CPU/GPU/memory/disk/network meters,
  and a seven-day weather forecast
- a **wallpaper picker** on Super + W that previews as you scroll and reverts
  if you leave without choosing
- a **lock screen** that captures the desktop before locking and blurs into
  it, authenticates over PAM, and puts itself up before the machine suspends

**The desktop** (`config/hypr/`) — Hyprland keybinds, window rules, sliding
workspace animations, and special workspaces that summon Spotify, Discord,
btop and a to-do app onto their own screens.

**The rest** — foot, fish with a Shortfin greeting, starship, fastfetch,
fuzzel, mako, btop, cava and nvtop, all wired into the same palette.

## Requirements

This is Hyprland-only and Arch-shaped. Specifically:

- **Hyprland 0.56 or newer.** The config is written in Lua, and older versions
  cannot read it at all.
- **Qt 6.7 or newer** — the shell uses `topLeftRadius`, which is 6.7+.
- **pywal16**, not pywal. The shell calls `wal --cols16`, which stock pywal
  does not have. The two packages conflict; the installer will tell you.
- **Nerd Fonts.** There is no fallback: without them every icon is a box.

The menus are dismissed by `HyprlandFocusGrab` and the workspace widgets read
Hyprland's IPC, so this will not work meaningfully on another compositor.

## Install

```sh
git clone https://github.com/Tychon15/shortfin.git
cd shortfin
./install.sh
```

`--dry-run` prints every action and changes nothing. `--no-packages` skips the
package step. `--uninstall` removes the links again.

Nothing is overwritten in place: anything already sitting at a destination is
moved into `~/.local/share/shortfin/backups/<timestamp>/` first, and the path
is printed when it finishes.

Configuration directories are **symlinked** into `~/.config`, so the repo
stays the source of truth and `git pull` updates your desktop. Three things
are copied rather than linked, because their applications write to them:
`btop.conf`, and everything under `~/.config/shortfin/`.

Then log out and back in — the Hyprland config and the session environment
are read at login — or start just the shell with `shell-switch shortfin`.

## Keybinds

`SUPER` is the modifier throughout. Tapping Super on its own opens the
launcher.

### Shell

| Key | Does |
| --- | --- |
| `SUPER` (tap) | Application launcher |
| `SUPER + W` | Wallpaper picker |
| `SUPER + L` | Lock |
| `SUPER + ALT + L` | Restart the shell, then lock |
| `SUPER + SHIFT + L` | Suspend |
| `CTRL + ALT + Delete` | Session menu |
| `CTRL + ALT + C` | Dismiss all notifications |
| bottom screen edge | Utility panel (media, performance, weather) |
| `CTRL + SUPER + SHIFT + R` | Kill the shell |
| `CTRL + SUPER + ALT + R` | Restart the shell |

### Applications

| Key | Does |
| --- | --- |
| `SUPER + T` | Terminal (foot) |
| `SUPER + N` | Browser (firefox) |
| `SUPER + C` | Editor (codium) |
| `SUPER + E` | File manager (thunar) |
| `CTRL + ALT + V` | Audio settings (pwvucontrol) |

Change these in `~/.config/shortfin/hypr-vars.lua`.

### Workspaces

| Key | Does |
| --- | --- |
| `SUPER + 1..0` | Go to workspace |
| `SUPER + ALT + 1..0` | Move window to workspace |
| `CTRL + SUPER + 1..0` | Go to workspace *group* (blocks of ten) |
| `SUPER + scroll`, `SUPER + Page Up/Down`, `CTRL + SUPER + Left/Right` | Previous / next workspace |
| `SUPER + ALT + scroll` | Move window to previous / next workspace |
| four-finger swipe | Slide between workspaces |

### Special workspaces

Each of these slides a workspace down over the current one, launching the
application if it is not already running.

| Key | Workspace |
| --- | --- |
| `SUPER + M` | Music (Spotify, Feishin, …) |
| `SUPER + D` | Communication (Discord, WhatsApp) |
| `SUPER + R` | To-do (Todoist) |
| `CTRL + SHIFT + Escape` | System monitor (btop) |
| `SUPER + S` | A general-purpose scratch workspace |

Which applications each one reaches for is set in
`~/.config/shortfin/toggles.json`.

### Windows

| Key | Does |
| --- | --- |
| `SUPER + Q` | Close |
| `SUPER + F` / `SUPER + ALT + F` | Fullscreen / maximised |
| `SUPER + arrows` | Move focus |
| `SUPER + SHIFT + arrows` | Move window |
| `SUPER + Minus` / `Equal` | Narrower / wider |
| `SUPER + SHIFT + Minus` / `Equal` | Shorter / taller |
| `SUPER + Z` / `SUPER + X` | Drag / resize with the mouse |
| `SUPER + P` | Pin |
| `SUPER + ALT + Space` | Float |
| `SUPER + ALT + Backslash` | Send to a corner, picture-in-picture style |
| `ALT + TAB` | Cycle windows |
| `SUPER + Comma` / `SUPER + U` | Group / ungroup |

### Utilities

| Key | Does |
| --- | --- |
| `Print` | Screenshot the screen to the clipboard |
| `SUPER + SHIFT + S` | Screenshot a region, screen frozen |
| `SUPER + SHIFT + ALT + S` | Screenshot a region |
| `SUPER + SHIFT + C` | Colour picker |
| `SUPER + V` / `SUPER + ALT + V` | Clipboard history / delete from it |
| `CTRL + SHIFT + ALT + V` | Type the most recent clipboard entry |
| `SUPER + Period` | Emoji picker |
| media / brightness / volume keys | As labelled |

## Configuring it

Everything of yours lives in `~/.config/shortfin/`, which the installer seeds
and then never touches again. Updating the repo cannot overwrite it.

| File | For |
| --- | --- |
| `config.json` | The shell — fonts, sizes, timings, wallpaper directory, weather location |
| `hypr-vars.lua` | Values in the Hyprland config — applications, gaps, opacity, keybinds |
| `hypr-user.lua` | Arbitrary Lua, run last — **monitors and keyboard layout go here** |
| `toggles.json` | Which applications the special-workspace keys summon |
| `user-config.fish` | Your shell aliases and environment |

`config.json` applies live — save the file and the bar re-reads it. The rest
need a Hyprland reload or a new shell.

Every key in `config.json` is optional and falls back to the shipped default,
so a typo costs you one setting rather than the bar. A few worth knowing:

| Key | Default | Notes |
| --- | --- | --- |
| `wallpaperDir` | `~/Pictures/Wallpapers` | `~/` is expanded |
| `weather.latitude` / `.longitude` | `0` | Unset means locate by IP — see the privacy note |
| `weather.units` | `"metric"` | `"imperial"` for °F and mph |
| `diskMount` | `"/"` | Which filesystem the disk meter watches |
| `cpuTempSensor` | `coretemp\|k10temp\|zenpower\|cpu_thermal` | First hwmon chip that matches |
| `font` / `iconFont` | RobotoMono / JetBrainsMono Nerd Font | The icon font must carry Material Design (`nf-md-*`) codepoints |

### Monitors and keyboard layout

The shipped config asks for the preferred mode at an automatic position and a
`us` keyboard, because that is the only thing that is right for everybody.
Yours goes in `~/.config/shortfin/hypr-user.lua`:

```lua
hl.config({ input = { kb_layout = "tr" } })

hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@165.00Hz",
    position = "auto",
    scale    = 1,
})
```

After editing anything under `config/hypr/`, check it before you log out:

```sh
shortfin-check-hypr          # loads the config outside Hyprland
shortfin-check-hypr --binds  # ... and lists every key it registers
```

A Lua error there is not something Hyprland reports gracefully —
`hyprctl configerrors` stays empty and you find out at the next login with no
keybinds. This catches it while you can still fix it.

## How the theming works

Changing the wallpaper — in the picker, or anywhere that sets it — runs
`wal` against the new image. pywal writes a palette to `~/.cache/wal/` and
sends the escape sequences that repaint every terminal already open.

**The shell does not use that palette raw.** It keeps the ground dark and the
text light, holds their hues, and takes the most saturated of colours 1–6 as
the accent — pywal is happy to hand a terminal a washed-out background, and
the bar has to stay readable over it. For one wallpaper here, pywal's
background is `#112027` and its colour 4 a muted `#467989`, while the bar
paints `#0d171c` with a `#42a3b8` accent. Anything themed from `~/.cache/wal`
directly therefore ends up looking like a *different* rice sitting next to
this one.

So the shell writes what it is actually painting with — colours and metrics
both — to `~/.cache/shortfin/palette.json`, and then runs
`shortfin-theme-reload`, which takes it the rest of the way:

- **mako** is rendered from `config/mako/config.in` using that palette, so a
  notification is drawn the way the launcher and the utility panel are: the
  bar's own ground, a border a shade lighter, the same corner radius, and type
  matching a launcher row — the summary in the plain foreground at the shell's
  size, the body smaller and dimmer beneath it. Note the `px` suffix on the
  font: pango sizes in points unless told otherwise, and the shell sizes in
  pixels, so without it every notification renders about a third too large.
  Reloaded in place, so it repaints immediately.
- **Hyprland** window borders and shadows take the shell's accent, so a
  focused window's border matches the bar above it. Set live via `hyprctl
  eval` — `hyprctl keyword` refuses to work with a Lua config — rather than
  by reloading, which would re-run every bind and rule on each step through
  the wallpaper picker.
- **foot** and **fuzzel** read `~/.cache/wal/` through an `include=` line, so
  the next window is themed. (`include` has to sit in the main section, above
  the first `[section]` header, in both.)
- **cava**, **nvtop**, **btop**, **GTK** and **Qt** are still generated from
  pywal's own palette via templates in `config/wal/templates/`, not the
  shell's. They read colours once at startup, so a running one keeps the
  palette it launched with.

To theme something else from pywal, drop a template into
`config/wal/templates/`; pywal renders every file there into `~/.cache/wal/`
under the same name. To theme it from the shell's palette instead, read
`~/.cache/shortfin/palette.json` and add a step to
`bin/shortfin-theme-reload`.

## What talks to the network

- `http://ip-api.com` — **plain HTTP**, and it sends your address, to work out
  where you are for the weather. Set `weather.latitude` and
  `weather.longitude` in `config.json` and this never runs.
- `https://api.open-meteo.com` — the forecast. No API key.
- `https://lrclib.net` — lyrics. Sends the artist, title, album and duration
  of whatever is playing, whenever the track changes.

Nothing else leaves the machine.

## Known rough edges

- The lock screen ships its own PAM stack (`assets/pam.d/passwd`) using
  `pam_faillock` and `pam_unix`. That is an Arch-shaped stack; other
  distributions order these differently and may need it adjusted.
- GTK and Qt applications need restarting to pick up a new palette. Nothing
  can repaint them in place.
- Qt's generated colour scheme flattens slightly: pywal has no "one step
  lighter than the background" entry, so alternate-row backgrounds collapse
  onto the background.
- The utility panel's hot edge stands down while a fullscreen window is
  focused, so it does not appear over a game.

## Licence

GPL-3.0. `config/hypr/` is a fork of the Hyprland configuration from
[caelestia](https://github.com/caelestia-dots/caelestia), also GPL-3.0 — see
[CREDITS.md](CREDITS.md), which also covers the fastfetch config and the
starship preset.

The bundled wallpaper is a third-party photograph and is **not** covered by
this licence: [wallpapers/CREDITS.md](wallpapers/CREDITS.md).
