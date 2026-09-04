# Credits

Shortfin is not built from nothing. These are the projects and people whose
work it is standing on.

## caelestia — the Hyprland configuration

`config/hypr/` is a fork of the Hyprland configuration from
[caelestia-dots/caelestia](https://github.com/caelestia-dots/caelestia),
GPL-3.0-only, taken at commit `1ee7a98`.

Most of it is theirs, essentially unchanged: the window and layer rules, the
tag system, the workspace-group navigation, the picture-in-picture placement
maths in `utils/functions.lua`, the gesture configuration, the animation
curves, and `utils/json.lua` (which is itself
[rxi/json.lua](https://github.com/rxi/json.lua)). Shortfin's contribution to
that directory is the rewiring: every shortcut that used to talk to
caelestia-shell now talks to shortfin or to a standalone tool, and the
override hooks were moved from `~/.config/caelestia/` to
`~/.config/shortfin/`.

If you want the shell those keybinds were originally written for, it is at
[caelestia-dots/shell](https://github.com/caelestia-dots/shell) and it is
worth your time. Shortfin is a different, smaller thing, not a replacement.

Shortfin is GPL-3.0 to match, as a derivative work must be.

## fastfetch configuration

`config/fastfetch/config.jsonc` is by **Bina**, credited in the file's own
header. It is kept as it was found.

## starship prompt

`config/starship.toml` is a customised version of a widely circulated
"geometric symbols" starship preset. Its colours are deliberately ANSI colour
*names* rather than hex values — that is what makes the prompt follow the
wallpaper, because the terminal's palette is what changes. Converting them to
hex would break the theming.

## Everything else

The Quickshell configuration under `config/quickshell/shortfin/`, the pywal
templates, the helper scripts in `bin/`, and the installer are original work.

The icons are Material Design codepoints from the
[Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) mapping.
Colour generation is [pywal16](https://github.com/eylles/pywal16), a fork of
[pywal](https://github.com/dylanaraps/pywal).
The shell itself runs on [Quickshell](https://quickshell.org/) (LGPL-3.0).

## Wallpaper

`wallpapers/shortfin-default.jpg` is a third-party photograph and is **not**
covered by this repository's licence. See
[wallpapers/CREDITS.md](wallpapers/CREDITS.md).
