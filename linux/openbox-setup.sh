#!/usr/bin/env bash
# openbox-setup.sh — persistent Openbox dev environment
# Survives reboot. Run as: sudo bash openbox-setup.sh
# After: log out → select "Openbox" at GDM/LightDM login screen
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { echo -e "\n${GREEN}==>${NC} $1"; }

USER_HOME="/home/${SUDO_USER}"
OBOX_CFG="$USER_HOME/.config/openbox"

# ── 1. INSTALL OPENBOX ECOSYSTEM ─────────────────────────────────────────────
step "Installing Openbox ecosystem + dev tools..."
apt-get install -y \
    openbox           `# window manager` \
    lightdm           `# lightweight display manager` \
    lightdm-gtk-greeter \
    tint2             `# taskbar / system tray` \
    rofi              `# app launcher (replaces dmenu)` \
    feh               `# wallpaper setter` \
    picom             `# compositor (transparency, shadows)` \
    dunst             `# notification daemon` \
    lxappearance      `# GTK theme switcher` \
    network-manager-gnome \
    volumeicon-alsa   `# volume tray icon` \
    xfce4-terminal    `# lightweight terminal` \
    thunar            `# lightweight file manager` \
    xfce4-screenshooter \
    arandr            `# display layout GUI` \
    numlockx          `# numlock on at login` \
    xss-lock          `# screen lock on suspend` \
    i3lock            `# lightweight screen locker` \
    fonts-jetbrains-mono \
    fonts-noto-color-emoji \
    breeze-icon-theme `# clean icon set` \
    arc-theme         `# clean dark GTK theme` \
    2>/dev/null

# ── 2. SWITCH DISPLAY MANAGER TO LIGHTDM ─────────────────────────────────────
step "Switching display manager to LightDM (lighter than GDM3)..."
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure lightdm 2>/dev/null || true
systemctl disable gdm3 2>/dev/null || true
systemctl enable lightdm 2>/dev/null || true
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager

# ── 3. REGISTER OPENBOX SESSION ──────────────────────────────────────────────
step "Registering Openbox X session..."
cat > /usr/share/xsessions/openbox-warble.desktop << 'EOF'
[Desktop Entry]
Name=Openbox (Warble)
Comment=Lightweight Openbox session for dev
Exec=/usr/bin/openbox-session
TryExec=/usr/bin/openbox
Type=Application
EOF

# ── 4. OPENBOX CONFIG ─────────────────────────────────────────────────────────
step "Writing Openbox config for $SUDO_USER..."
mkdir -p "$OBOX_CFG"

# rc.xml — keybindings + behavior
cat > "$OBOX_CFG/rc.xml" << 'RCEOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">

  <resistance><strength>10</strength><screen_edge_strength>20</screen_edge_strength></resistance>
  <focus><focusNew>yes</focusNew><followMouse>no</followMouse><focusLast>yes</focusLast><underMouse>no</underMouse><focusDelay>200</focusDelay><raiseOnFocus>no</raiseOnFocus></focus>
  <placement><policy>Smart</policy><center>yes</center><monitor>Primary</monitor></placement>

  <theme>
    <name>Arc-Dark</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>no</animateIconify>
    <font place="ActiveWindow"><name>JetBrains Mono</name><size>10</size><weight>Bold</weight></font>
    <font place="InactiveWindow"><name>JetBrains Mono</name><size>10</size><weight>Normal</weight></font>
    <font place="MenuHeader"><name>JetBrains Mono</name><size>10</size><weight>Bold</weight></font>
    <font place="MenuItem"><name>JetBrains Mono</name><size>10</size><weight>Normal</weight></font>
    <font place="OSD"><name>JetBrains Mono</name><size>12</size><weight>Bold</weight></font>
  </theme>

  <desktops><number>4</number><firstdesk>1</firstdesk><names><name>dev</name><name>browser</name><name>comms</name><name>misc</name></names><popupTime>875</popupTime></desktops>

  <resize><drawContents>yes</drawContents><popupShow>Nonpixel</popupShow><popupPosition>Center</popupPosition></resize>
  <margins><top>0</top><bottom>30</bottom><left>0</left><right>0</right></margins>

  <keyboard>
    <!-- Launch terminal -->
    <keybind key="super-Return"><action name="Execute"><command>xfce4-terminal</command></action></keybind>
    <!-- Rofi app launcher -->
    <keybind key="super-space"><action name="Execute"><command>rofi -show drun -theme warble</command></action></keybind>
    <!-- Rofi window switcher -->
    <keybind key="super-Tab"><action name="Execute"><command>rofi -show window -theme warble</command></action></keybind>
    <!-- Close window -->
    <keybind key="super-q"><action name="Close"/></keybind>
    <!-- Maximize -->
    <keybind key="super-m"><action name="Maximize"/></keybind>
    <!-- Snap left/right -->
    <keybind key="super-Left"><action name="UnmaximizeFull"/><action name="MoveResizeTo"><x>0</x><y>0</y><width>50%</width><height>100%</height></action></keybind>
    <keybind key="super-Right"><action name="UnmaximizeFull"/><action name="MoveResizeTo"><x>50%</x><y>0</y><width>50%</width><height>100%</height></action></keybind>
    <!-- Workspaces -->
    <keybind key="super-1"><action name="GoToDesktop"><to>1</to></action></keybind>
    <keybind key="super-2"><action name="GoToDesktop"><to>2</to></action></keybind>
    <keybind key="super-3"><action name="GoToDesktop"><to>3</to></action></keybind>
    <keybind key="super-4"><action name="GoToDesktop"><to>4</to></action></keybind>
    <!-- Move window to workspace -->
    <keybind key="super-shift-1"><action name="SendToDesktop"><to>1</to><follow>yes</follow></action></keybind>
    <keybind key="super-shift-2"><action name="SendToDesktop"><to>2</to><follow>yes</follow></action></keybind>
    <keybind key="super-shift-3"><action name="SendToDesktop"><to>3</to><follow>yes</follow></action></keybind>
    <keybind key="super-shift-4"><action name="SendToDesktop"><to>4</to><follow>yes</follow></action></keybind>
    <!-- Screenshot -->
    <keybind key="Print"><action name="Execute"><command>xfce4-screenshooter -f</command></action></keybind>
    <keybind key="super-Print"><action name="Execute"><command>xfce4-screenshooter -r</command></action></keybind>
    <!-- Lock screen -->
    <keybind key="super-l"><action name="Execute"><command>i3lock -c 0a1628</command></action></keybind>
    <!-- File manager -->
    <keybind key="super-e"><action name="Execute"><command>thunar</command></action></keybind>
    <!-- Reload Openbox -->
    <keybind key="super-shift-r"><action name="Reconfigure"/></keybind>
  </keyboard>

  <mouse>
    <dragThreshold>8</dragThreshold>
    <doubleClickTime>200</doubleClickTime>
    <screenEdgeWarpTime>0</screenEdgeWarpTime>
    <context name="Frame">
      <mousebind button="A-Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="A-Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="A-Right" action="Drag"><action name="Resize"/></mousebind>
      <mousebind button="A-Middle" action="Press"><action name="Lower"/></mousebind>
    </context>
    <context name="Desktop">
      <mousebind button="Right" action="Press"><action name="ShowMenu"><menu>root-menu</menu></action></mousebind>
      <mousebind button="Middle" action="Press"><action name="ShowMenu"><menu>client-list-combined-menu</menu></action></mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="Left" action="DoubleClick"><action name="Maximize"/></mousebind>
      <mousebind button="Right" action="Press"><action name="ShowMenu"><menu>client-menu</menu></action></mousebind>
    </context>
    <context name="Client">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
    </context>
  </mouse>

  <menu>
    <file>menu.xml</file>
    <hideDelay>200</hideDelay>
    <middle>no</middle>
    <submenuShowDelay>100</submenuShowDelay>
    <applicationIcons>yes</applicationIcons>
    <manageDesktops>yes</manageDesktops>
  </menu>

  <applications>
    <!-- VSCode: always on desktop 1, maximized -->
    <application name="code"><desktop>1</desktop><maximized>yes</maximized></application>
    <!-- Browser: always on desktop 2 -->
    <application name="firefox"><desktop>2</desktop><maximized>yes</maximized></application>
    <application name="chromium-browser"><desktop>2</desktop><maximized>yes</maximized></application>
    <!-- Terminal: sensible default size -->
    <application name="xfce4-terminal"><desktop>1</desktop></application>
  </applications>

</openbox_config>
RCEOF

# menu.xml — right-click desktop menu
cat > "$OBOX_CFG/menu.xml" << 'MENUEOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">

<menu id="root-menu" label="Warble Dev">
  <item label="Terminal"><action name="Execute"><command>xfce4-terminal</command></action></item>
  <item label="Code"><action name="Execute"><command>code</command></action></item>
  <item label="Browser"><action name="Execute"><command>firefox</command></action></item>
  <item label="Files"><action name="Execute"><command>thunar</command></action></item>
  <separator/>
  <menu id="dev-menu" label="Dev Tools">
    <item label="htop"><action name="Execute"><command>xfce4-terminal -e htop</command></action></item>
    <item label="ncdu"><action name="Execute"><command>xfce4-terminal -e ncdu</command></action></item>
    <item label="Docker (nerdctl ps)"><action name="Execute"><command>xfce4-terminal -e "nerdctl ps"</command></action></item>
    <item label="Display settings"><action name="Execute"><command>arandr</command></action></item>
  </menu>
  <separator/>
  <item label="Lock"><action name="Execute"><command>i3lock -c 0a1628</command></action></item>
  <item label="Logout"><action name="Exit"><prompt>no</prompt></action></item>
  <item label="Reboot"><action name="Execute"><command>systemctl reboot</command></action></item>
  <item label="Shutdown"><action name="Execute"><command>systemctl poweroff</command></action></item>
</menu>

<menu id="client-list-combined-menu"/>

</openbox_menu>
MENUEOF

# autostart — what launches on login
cat > "$OBOX_CFG/autostart" << 'AUTOEOF'
# Openbox autostart — warble dev session

# compositor (subtle shadows, no blur — keeps GPU load minimal)
picom --daemon --backend glx --vsync --shadow --shadow-radius 8 --shadow-opacity 0.4 --no-fading-openclose &

# taskbar
tint2 &

# wallpaper (dark solid — no RAM wasted on image)
feh --bg-color "#0a1628" &

# notifications
dunst &

# network tray
nm-applet &

# volume tray
volumeicon &

# numlock on
numlockx on &

# lock screen on lid close / suspend
xss-lock -- i3lock -c 0a1628 &

# polkit agent (needed for sudo GUI prompts)
/usr/libexec/polkit-gnome-authentication-agent-1 &
AUTOEOF

# ── 5. TINT2 CONFIG ───────────────────────────────────────────────────────────
step "Writing tint2 taskbar config..."
mkdir -p "$USER_HOME/.config/tint2"
cat > "$USER_HOME/.config/tint2/tint2rc" << 'TINTEOF'
# tint2 — minimal dark taskbar for warble dev

panel_monitor = all
panel_position = bottom center horizontal
panel_size = 100% 30
panel_margin = 0 0
panel_padding = 2 0 2
panel_background_id = 1
wm_menu = 0
panel_dock = 0
panel_layer = top
panel_items = TSC

# Taskbar
taskbar_mode = multi_desktop
taskbar_padding = 0 3 2
taskbar_background_id = 0
taskbar_active_background_id = 2
taskbar_name = 1
taskbar_name_padding = 4 2
taskbar_name_background_id = 0
taskbar_name_active_background_id = 2

# Tasks
task_text = 1
task_icon = 1
task_centered = 1
task_maximum_size = 180 30
task_padding = 4 3 4
task_background_id = 0
task_active_background_id = 2
task_font = JetBrains Mono 9
task_font_color = #9bb6d4 100
task_active_font_color = #e8f3ff 100
urgent_nb_of_blink = 8

# Systray
systray_padding = 4 4 4
systray_sort = ascending
systray_icon_size = 18
systray_icon_asb = 100 0 0
systray_background_id = 0

# Clock
time1_format = %H:%M
time2_format = %a %d %b
time1_font = JetBrains Mono Bold 11
time2_font = JetBrains Mono 8
clock_font_color = #e8f3ff 100
clock_padding = 8 0
clock_background_id = 0

# Backgrounds
rounded = 4
border_width = 0

# BG 1 — panel
background_color = #0d2e52 100
border_color = #0d2e52 0

# BG 2 — active task
background_color = #1fb8a8 20
border_color = #1fb8a8 60
TINTEOF

# ── 6. ROFI THEME ─────────────────────────────────────────────────────────────
step "Writing Rofi launcher theme..."
mkdir -p "$USER_HOME/.config/rofi"
cat > "$USER_HOME/.config/rofi/warble.rasi" << 'ROFIEOF'
* {
    bg:      #0a1628ee;
    bg-sel:  #1fb8a820;
    border:  #1fb8a8;
    fg:      #e8f3ff;
    fg-dim:  #9bb6d4;
    font:    "JetBrains Mono 12";
}
window { background-color: @bg; border: 1px; border-color: @border; border-radius: 6px; width: 480px; }
mainbox { padding: 8px; }
inputbar { padding: 8px 12px; background-color: #0d2e52; border-radius: 4px; margin-bottom: 8px; }
entry { text-color: @fg; }
prompt { text-color: @border; margin-right: 8px; }
listview { lines: 8; scrollbar: false; }
element { padding: 8px 12px; border-radius: 4px; }
element normal.normal { text-color: @fg; background-color: transparent; }
element selected.normal { text-color: @fg; background-color: @bg-sel; border: 1px; border-color: @border; }
element-text { text-color: inherit; }
ROFIEOF

# ── 7. DUNST CONFIG ───────────────────────────────────────────────────────────
step "Writing dunst notification config..."
mkdir -p "$USER_HOME/.config/dunst"
cat > "$USER_HOME/.config/dunst/dunstrc" << 'DUNSTEOF'
[global]
    monitor = 0
    follow = none
    geometry = "320x5-12+42"
    shrink = yes
    transparency = 10
    padding = 10
    horizontal_padding = 12
    frame_width = 1
    frame_color = "#1fb8a8"
    font = JetBrains Mono 10
    line_height = 4
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    show_age_threshold = 60
    word_wrap = yes
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    icon_position = left
    max_icon_size = 32
    browser = firefox

[urgency_low]
    background = "#0d2e52"
    foreground = "#9bb6d4"
    timeout = 4

[urgency_normal]
    background = "#0d2e52"
    foreground = "#e8f3ff"
    timeout = 6

[urgency_critical]
    background = "#1a0a0a"
    foreground = "#ff6b6b"
    frame_color = "#ff6b6b"
    timeout = 0
DUNSTEOF

# ── 8. GTK THEME (dark, applies system-wide) ──────────────────────────────────
step "Setting GTK dark theme..."
mkdir -p "$USER_HOME/.config/gtk-3.0"
cat > "$USER_HOME/.config/gtk-3.0/settings.ini" << 'GTKEOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=breeze-dark
gtk-font-name=JetBrains Mono 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-button-images=0
gtk-menu-images=1
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
GTKEOF

cat > "$USER_HOME/.gtkrc-2.0" << 'GTK2EOF'
gtk-theme-name="Arc-Dark"
gtk-icon-theme-name="breeze-dark"
gtk-font-name="JetBrains Mono 10"
gtk-cursor-theme-name="Adwaita"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-button-images=0
gtk-menu-images=1
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
GTK2EOF

# ── 9. XFCE4-TERMINAL CONFIG ──────────────────────────────────────────────────
step "Configuring xfce4-terminal..."
mkdir -p "$USER_HOME/.config/xfce4/terminal"
cat > "$USER_HOME/.config/xfce4/terminal/terminalrc" << 'TERMEOF'
[Configuration]
FontName=JetBrains Mono 12
ColorForeground=#e8f3ff
ColorBackground=#0a1628
ColorCursor=#1fb8a8
ColorBold=#ffffff
ColorPalette=#0a1628;#ff6b6b;#1fb8a8;#ffb454;#7ec8ff;#c678dd;#56b6c2;#abb2bf;#5c6370;#e06c75;#98c379;#e5c07b;#61afef;#c678dd;#56b6c2;#ffffff
MiscBellUrgent=FALSE
MiscBordersDefault=FALSE
MiscCursorBlinks=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=120x35
MiscInheritGeometry=FALSE
MiscMenubarDefault=FALSE
MiscMouseAutohide=TRUE
MiscToolbarDefault=FALSE
MiscConfirmClose=FALSE
MiscCycleTabs=TRUE
MiscTabCloseButtons=TRUE
MiscTabPosition=GTK_POS_TOP
ScrollingBar=TERMINAL_SCROLLBAR_NONE
ScrollingLines=5000
ShortcutsNoMenukey=TRUE
TabActivityColor=#1fb8a8
TitleMode=TERMINAL_TITLE_REPLACE
TERMEOF

# ── 10. FIX OWNERSHIP ────────────────────────────────────────────────────────
step "Fixing file ownership..."
chown -R "${SUDO_USER}:${SUDO_USER}" \
    "$OBOX_CFG" \
    "$USER_HOME/.config/tint2" \
    "$USER_HOME/.config/rofi" \
    "$USER_HOME/.config/dunst" \
    "$USER_HOME/.config/gtk-3.0" \
    "$USER_HOME/.config/xfce4" \
    "$USER_HOME/.gtkrc-2.0"

# ── 11. PICOM CONFIG ──────────────────────────────────────────────────────────
step "Writing picom compositor config..."
mkdir -p "$USER_HOME/.config/picom"
cat > "$USER_HOME/.config/picom/picom.conf" << 'PICOMEOF'
# picom — minimal compositor for openbox
backend = "glx";
vsync = true;
shadow = true;
shadow-radius = 8;
shadow-opacity = 0.4;
shadow-offset-x = -8;
shadow-offset-y = -8;
shadow-exclude = ["name = 'Notification'", "class_g = 'tint2'", "class_g = 'dunst'"];
fading = false;
inactive-opacity = 1.0;
active-opacity = 1.0;
frame-opacity = 1.0;
detect-rounded-corners = true;
detect-client-opacity = true;
mark-wmwin-focused = true;
mark-ovredir-focused = true;
use-ewmh-active-win = true;
PICOMEOF
chown -R "${SUDO_USER}:${SUDO_USER}" "$USER_HOME/.config/picom"

# ── 12. FINAL SUMMARY ────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════"
echo " Openbox dev environment ready."
echo "════════════════════════════════════════════════════"
echo ""
echo " Display manager: LightDM (replaces GDM3)"
echo " Session:         Openbox (Warble)"
echo " Theme:           Arc-Dark + Breeze icons"
echo " Font:            JetBrains Mono"
echo " Terminal:        xfce4-terminal (Super+Enter)"
echo " Launcher:        Rofi (Super+Space)"
echo " Workspaces:      4 (dev / browser / comms / misc)"
echo ""
echo " Keybindings:"
echo "   Super+Enter     → terminal"
echo "   Super+Space     → app launcher (rofi)"
echo "   Super+Tab       → window switcher"
echo "   Super+Q         → close window"
echo "   Super+M         → maximize"
echo "   Super+←/→       → snap left/right"
echo "   Super+1-4       → switch workspace"
echo "   Super+Shift+1-4 → move window to workspace"
echo "   Super+L         → lock screen"
echo "   Super+E         → file manager"
echo "   Print           → screenshot fullscreen"
echo "   Super+Shift+R   → reload Openbox"
echo "   Right-click desktop → app menu"
echo ""
echo " NEXT: reboot → at login screen click gear icon → select 'Openbox (Warble)'"
echo ""
