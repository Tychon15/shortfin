local vars = require("variables")

local function tagged_rule(tag, matches, field)
    for _, match in ipairs(matches) do
        if field then
            local table = {}
            table[field] = match
            match = table
        end
        hl.window_rule({ match = match, tag = "+" .. tag })
    end
end

local function create_tag(tag, rules)
    local rule = { match = { tag = tag } }
    for k, v in pairs(rules) do
        rule[k] = v
    end
    hl.window_rule(rule)
end

local opaque_tag = "opaque"
local float_tag = "float"
local float_60_70_tag = "float_60_70"
local float_70_80_tag = "float_70_80"
local float_50_60_tag = "float_50_60"
local game_tag = "game"
local xwl_popup_tag = "xwl_popup"
local system_monitor_tag = "system_monitor"
local music_player_tag = "music_player"
local communication_app_tag = "communication_app"
local todo_app_tag = "todo_app"

hl.window_rule({ match = { fullscreen = false }, opacity = vars.windowOpacity .. " override" })

hl.window_rule({ match = { float = true, xwayland = false }, center = true })

hl.window_rule({
    match             = { title = "Picture(-| )in(-| )[Pp]icture" },
    move              = "(monitor_w*0.98-window_w) (monitor_h*0.97-window_h)",
    pin               = true,
    float             = true,
    keep_aspect_ratio = true,
})

tagged_rule(opaque_tag, {
    "foot",
    "equibop",
    "org.quickshell",
    "feh|imv|swappy",
    "krita|gimp|inkscape|darktable",
    "resolve|kdenlive|shotcut",
    "blender|godot",
}, "class")

tagged_rule(float_tag, {
    "guifetch",
    "yad|zenity",
    "wev",
    "org.gnome.FileRoller|file-roller",
    "blueman-manager",
    "com.github.GradienceTeam.Gradience",
    "feh|imv|swappy",
    "org.quickshell",
}, "class")
tagged_rule(float_tag, {
    "File (Operation|Upload)( Progress)?",
    ".* Properties",
    'Rename ".*"',
}, "title")

tagged_rule(float_60_70_tag, {
    "(Select|Open)( a)? (File|Folder)(s)?",
    "Save As",
    "Library",
}, "title")
tagged_rule(float_60_70_tag, {
    { title = "(Save|Export) Image", class = "gimp" },
})
tagged_rule(float_60_70_tag, {
    "org.pulseaudio.pavucontrol|com.saivert.pwvucontrol",
    "yad-icon-browser",
}, "class")

tagged_rule(float_70_80_tag, {
    "org.gnome.Settings",
}, "class")

tagged_rule(float_50_60_tag, {
    "nwg-look",
    "system-config-printer",
}, "class")

tagged_rule(game_tag, {
    "steam_app_[0-9]+",
    "steam_app_default",
    "gamescope",
}, "class")

tagged_rule(xwl_popup_tag, {
    { xwayland = true, title = "win[0-9]+" },
    { xwayland = true, title = "",         class = "", initial_title = "", initial_class = "" }
})

tagged_rule(system_monitor_tag, { "btop" }, "class")
tagged_rule(music_player_tag, {
    "feishin|Supersonic|Plexamp",
    "Spotify",
    "Cider",
    "com.github.th-ch.youtube-music|com-maxrave-simpmusic-MainKt",
}, "class")
tagged_rule(music_player_tag, {
    "Spotify|Spotify Free"
}, "initial_title")
tagged_rule(communication_app_tag, {
    "discord|equibop|vesktop",
    "whatsapp"
}, "class")
tagged_rule(todo_app_tag, {
    "todoist"
}, "class")

tagged_rule(float_tag, { { class = "steam", title = "Friends List" } })
tagged_rule(xwl_popup_tag, { { class = "steam", title = "" } })

hl.window_rule({ match = { class = "ueberzugpp_.*" }, float = true, no_initial_focus = true })

hl.window_rule({ match = { class = "fusion360.exe", title = "Fusion360|(Marking Menu)" }, no_blur = true })

tagged_rule(float_tag, {
    { class = "com-atlauncher-App", title = "ATLauncher Console" },
    { class = "PandoraLauncher",    title = "Minecraft Game Output" },
})

create_tag(opaque_tag, { opaque = true })
create_tag(float_tag, { float = true })
create_tag(float_50_60_tag, { float = true, size = "(monitor_w*0.5) (monitor_h*0.6)", center = true })
create_tag(float_60_70_tag, { float = true, size = "(monitor_w*0.6) (monitor_h*0.7)", center = true })
create_tag(float_70_80_tag, { float = true, size = "(monitor_w*0.7) (monitor_h*0.8)", center = true })
create_tag(game_tag, { opaque = true, immediate = true, idle_inhibit = "always" })
create_tag(xwl_popup_tag, {
    no_dim = true,
    no_shadow = true,
    no_blur = true,
    opaque = true,
    rounding = math.min(10, vars.windowRounding),
})
create_tag(system_monitor_tag, { workspace = "special:sysmon" })
create_tag(music_player_tag, { workspace = "special:music" })
create_tag(communication_app_tag, { workspace = "special:communication" })
create_tag(todo_app_tag, { workspace = "special:todo" })

hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = vars.singleWindowGapsOut })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = vars.singleWindowGapsOut })

hl.layer_rule({ match = { namespace = "hyprpicker" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "logout_dialog" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "selection" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "wayfreeze" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "launcher" }, animation = "popin 80%", blur = true })
