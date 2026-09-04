function fish_greeting
    echo -ne '\x1b[1m\x1b[36m'
    echo '     _____ __               __  _____      '
    echo '    / ___// /_  ____  _____/ /_/ __(_)___  '
    echo '    \__ \/ __ \/ __ \/ ___/ __/ /_/ / __ \ '
    echo '   ___/ / / / / /_/ / /  / /_/ __/ / / / / '
    echo '  /____/_/ /_/\____/_/   \__/_/ /_/_/ /_/  '
    set_color normal
    command -v fastfetch &> /dev/null && fastfetch --key-padding-left 5
end
