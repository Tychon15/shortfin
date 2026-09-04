#!/usr/bin/env bash

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
conf="${XDG_CONFIG_HOME:-$HOME/.config}"
cache="${XDG_CACHE_HOME:-$HOME/.cache}"
bin_dir="$HOME/.local/bin"
stamp="$(date +%Y%m%d-%H%M%S)"
backups="$HOME/.local/share/shortfin/backups/$stamp"

dry_run=false
uninstall=false
do_packages=true
backed_up=false

for arg in "$@"; do
    case "$arg" in
        --dry-run)     dry_run=true ;;
        --uninstall)   uninstall=true ;;
        --no-packages) do_packages=false ;;
        -h|--help)
            cat <<'USAGE'
install.sh — put shortfin in place.

  ./install.sh                 install
  ./install.sh --dry-run       print every action, change nothing
  ./install.sh --uninstall     remove the links this created
  ./install.sh --no-packages   skip the package step

Nothing is overwritten in place: anything already at a destination is moved
into ~/.local/share/shortfin/backups/<timestamp>/ first.
USAGE
            exit 0 ;;
        *) echo "install.sh: unknown option '$arg' (try --help)" >&2; exit 2 ;;
    esac
done


bold=$(tput bold 2>/dev/null || true)
dim=$(tput dim 2>/dev/null || true)
red=$(tput setaf 1 2>/dev/null || true)
yellow=$(tput setaf 3 2>/dev/null || true)
reset=$(tput sgr0 2>/dev/null || true)

step() { printf '%s==>%s %s\n' "$bold" "$reset" "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '    %s!%s %s\n' "$yellow" "$reset" "$*" >&2; }
die()  { printf '%s==> error:%s %s\n' "$red" "$reset" "$*" >&2; exit 1; }
run()  { if $dry_run; then printf '    %s[dry-run]%s %s\n' "$dim" "$reset" "$*"; else "$@"; fi; }


links=(
    "config/quickshell/shortfin:$conf/quickshell/shortfin"
    "config/hypr:$conf/hypr"
    "config/fish:$conf/fish"
    "config/foot:$conf/foot"
    "config/fastfetch:$conf/fastfetch"
    "config/fuzzel:$conf/fuzzel"
    "config/starship.toml:$conf/starship.toml"
    "config/wal/templates:$conf/wal/templates"
    "config/qtengine/config.json:$conf/qtengine/config.json"
    "config/uwsm/env:$conf/uwsm/env"
    "config/uwsm/env-hyprland:$conf/uwsm/env-hyprland"
)

seeds=(
    "config/btop/btop.conf:$conf/btop/btop.conf"
    "examples/config.json:$conf/shortfin/config.json"
    "examples/hypr-user.lua:$conf/shortfin/hypr-user.lua"
    "examples/hypr-vars.lua:$conf/shortfin/hypr-vars.lua"
    "examples/toggles.json:$conf/shortfin/toggles.json"
    "examples/user-config.fish:$conf/shortfin/user-config.fish"
)

scripts=(shell-switch shortfin-theme-reload shortfin-clipboard shortfin-emoji shortfin-check-hypr)

packages=(
    hyprland quickshell uwsm
    foot fish starship eza zoxide direnv fastfetch
    fuzzel mako btop cava nvtop
    grim slurp hyprshot hyprpicker cliphist wl-clipboard
    brightnessctl playerctl networkmanager
    pipewire pipewire-pulse wireplumber
    polkit-gnome gnome-keyring trash-cli gammastep bluez-utils geoclue
    libnotify unicode-emoji python
    ttf-jetbrains-mono-nerd ttf-roboto-mono-nerd
    papirus-icon-theme adw-gtk-theme adwaita-cursors
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
)

aur_packages=(python-pywal16 qtengine darkly-bin)


if $uninstall; then
    step "Removing shortfin links"
    for entry in "${links[@]}"; do
        dest="${entry#*:}"
        if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$repo/${entry%%:*}")" ]; then
            info "unlink ${dest/#$HOME/\~}"
            run rm -f "$dest"
        fi
    done
    for script in "${scripts[@]}"; do
        if [ -L "$bin_dir/$script" ]; then
            info "unlink ~/.local/bin/$script"
            run rm -f "$bin_dir/$script"
        fi
    done
    echo
    info "Copied files and generated themes were left alone."
    info "Earlier backups are under ~/.local/share/shortfin/backups/"
    exit 0
fi


step "Checking this machine"

[ -r /etc/arch-release ] || command -v pacman >/dev/null 2>&1 ||
    warn "This installer only knows how to install packages with pacman. Use --no-packages and install the dependencies listed in the README by hand."

if command -v hyprctl >/dev/null 2>&1; then
    hypr_version=$(hyprctl version 2>/dev/null | sed -n '1s/.*v\([0-9]*\.[0-9]*\).*/\1/p')
    if [ -n "$hypr_version" ]; then
        major=${hypr_version%%.*}; minor=${hypr_version#*.}
        if [ "$major" -eq 0 ] && [ "$minor" -lt 56 ]; then
            die "Hyprland $hypr_version is too old. The config is written in Lua, which needs Hyprland 0.56 or newer."
        fi
        info "Hyprland $hypr_version"
    fi
else
    info "Hyprland is not installed yet; it is in the package list below."
fi

if pacman -Qq xdg-desktop-portal-kde >/dev/null 2>&1; then
    warn "xdg-desktop-portal-kde is installed and competes with the Hyprland portal for screen sharing and file dialogs. Consider removing it."
fi

if pacman -Qq python-pywal >/dev/null 2>&1; then
    warn "python-pywal is installed, but shortfin needs python-pywal16 (for --cols16) and the two conflict. Remove python-pywal first: sudo pacman -R python-pywal"
fi


if $do_packages && command -v pacman >/dev/null 2>&1; then
    step "Packages"

    missing=()
    for pkg in "${packages[@]}"; do
        pacman -Qq "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done

    if [ ${#missing[@]} -gt 0 ]; then
        info "installing: ${missing[*]}"
        run sudo pacman -S --needed --noconfirm "${missing[@]}"
    else
        info "all repository packages already installed"
    fi

    aur_missing=()
    for pkg in "${aur_packages[@]}"; do
        pacman -Qq "$pkg" >/dev/null 2>&1 || aur_missing+=("$pkg")
    done

    if [ ${#aur_missing[@]} -gt 0 ]; then
        helper=""
        for candidate in paru yay; do
            command -v "$candidate" >/dev/null 2>&1 && { helper="$candidate"; break; }
        done

        if [ -n "$helper" ]; then
            info "installing from the AUR with $helper: ${aur_missing[*]}"
            run "$helper" -S --needed --noconfirm "${aur_missing[@]}"
        else
            warn "No AUR helper (paru or yay) found. Install these by hand, or the shell will run on its fallback palette: ${aur_missing[*]}"
        fi
    else
        info "all AUR packages already installed"
    fi
else
    step "Packages (skipped)"
fi


preserve() {
    local dest=$1

    [ -L "$dest" ] && { run rm -f "$dest"; return; }
    [ -e "$dest" ] || return 0

    local rel="${dest#"$HOME"/}"
    info "backing up ${dest/#$HOME/\~}"
    run mkdir -p "$backups/$(dirname "$rel")"
    run mv "$dest" "$backups/$rel"
    backed_up=true
}

step "Linking configuration"

for entry in "${links[@]}"; do
    src="$repo/${entry%%:*}"
    dest="${entry#*:}"

    [ -e "$src" ] || die "missing from the repo: ${entry%%:*}"

    preserve "$dest"
    run mkdir -p "$(dirname "$dest")"
    run ln -sfn "$src" "$dest"
    info "${dest/#$HOME/\~} -> ${src#"$repo"/}"
done

step "Installing scripts"
run mkdir -p "$bin_dir"
for script in "${scripts[@]}"; do
    preserve "$bin_dir/$script"
    run ln -sfn "$repo/bin/$script" "$bin_dir/$script"
    info "~/.local/bin/$script"
done

step "Seeding your own settings"
for entry in "${seeds[@]}"; do
    src="$repo/${entry%%:*}"
    dest="${entry#*:}"

    if [ -e "$dest" ]; then
        info "keeping your ${dest/#$HOME/\~}"
        continue
    fi

    run mkdir -p "$(dirname "$dest")"
    run cp "$src" "$dest"
    info "${dest/#$HOME/\~}"
done


step "Wallpapers"
wallpapers="$HOME/Pictures/Wallpapers"
run mkdir -p "$wallpapers"

if [ -z "$(find "$wallpapers" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \) \
        -print -quit 2>/dev/null)" ]; then
    info "adding the default wallpaper — see wallpapers/CREDITS.md, it is not covered by this repo's licence"
    run cp "$repo/wallpapers/shortfin-default.jpg" "$wallpapers/"
else
    info "you already have wallpapers; leaving them alone"
fi

step "Generating the first palette"
if command -v wal >/dev/null 2>&1; then
    first=$(find "$wallpapers" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \) \
        2>/dev/null | sort | head -1)

    if [ -n "$first" ]; then
        run wal -i "$first" -n -t -e -q --cols16 lighten
        run "$repo/bin/shortfin-theme-reload"
        info "palette built from $(basename "$first")"
    fi
else
    warn "pywal is not installed, so mako, cava, nvtop, GTK and Qt have no colours yet. Install python-pywal16 and change the wallpaper once."
fi


echo
step "Done"

if $dry_run; then
    info "That was a dry run. Nothing changed."
    exit 0
fi

$backed_up && info "Your previous files are in ${backups/#$HOME/\~}"

cat <<'EOF'

    Log out and back in to pick up the Hyprland config and the session
    environment, or start the shell right now with:

        shell-switch shortfin

    Machine-specific settings — monitors, keyboard layout — go in
    ~/.config/shortfin/hypr-user.lua. The shipped config uses the preferred
    mode at an automatic position and a "us" keyboard.

EOF
