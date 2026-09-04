# shortfin

## Install

```sh
git clone https://github.com/Tychon15/shortfin.git
cd shortfin
./install.sh
```

```sh
./install.sh --no-packages  # hold the packages
./install.sh --uninstall
```

```sh
shell-switch shortfin       # start the shell without logging out
```

## Keybinds

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
