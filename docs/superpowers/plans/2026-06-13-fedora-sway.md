# Fedora-Sway Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Fedora Sway installer (`Fedora-Sway`) and a distro-agnostic Sway dotfiles repo (`Sway-Dots`) by forking and translating JaKooLit's `Fedora-Hyprland` + `Hyprland-Dots`, reaching full ricing parity using the closest wlroots tool for each Hyprland feature.

**Architecture:** Two repos. `Fedora-Sway` mirrors the upstream modular installer (whiptail TUI → COPR → package scripts → SDDM/fonts/themes → clone+run Sway-Dots `copy.sh`). `Sway-Dots` copies the ~10 WM-agnostic config dirs verbatim, translates `config/hypr` → `config/sway`, and rewrites `hyprctl`→`swaymsg` across 53 scripts. Sway core is in Fedora main repos; no COPR for the WM.

**Tech Stack:** Bash, whiptail/newt, dnf + COPR, Sway (wlroots), swayidle, swaylock-effects, swww, wlsunset, waybar, swaync, rofi, wlogout, wallust, nwg-displays.

**Verification model (no unit-test framework for dotfiles):** Each task verifies with one or more of: `shellcheck`, `bash -n`, `sway -C <config>` (validate, needs sway installed — run in the test VM), `jq -e` on JSON configs, and a final VM smoke test. Treat these as the "tests".

**Reference checkout:** Upstream is cloned at `/tmp/Fedora-Hyprland` and `/tmp/Hyprland-Dots`. Re-clone if missing:
```bash
git clone --depth 1 https://github.com/JaKooLit/Fedora-Hyprland.git /tmp/Fedora-Hyprland
git clone --depth 1 https://github.com/JaKooLit/Hyprland-Dots.git /tmp/Hyprland-Dots
```

**Working dirs:** `~/Fedora-Sway` (already git-init'd, holds this plan) and `~/Sway-Dots` (created in Task 8). Remotes: `github.com/seyboo/Fedora-Sway`, `github.com/seyboo/Sway-Dots`.

---

## Phase 1 — Fedora-Sway installer skeleton

### Task 1: Installer support files (Global_functions, copr, fonts, near-verbatim scripts)

**Files:**
- Create: `~/Fedora-Sway/install-scripts/Global_functions.sh`
- Create: `~/Fedora-Sway/install-scripts/copr.sh`
- Create: `~/Fedora-Sway/install-scripts/fonts.sh`
- Copy near-verbatim: `sddm.sh`, `sddm_theme.sh`, `gtk_themes.sh`, `bluetooth.sh`, `thunar.sh`, `thunar_default.sh`, `zsh.sh`, `zsh_pokemon.sh`, `nvidia.sh`, `rog.sh`, `InputGroup.sh`, `temp-monitor.sh`, `disk-monitor.sh`, `battery-monitor.sh`
- Copy: `~/Fedora-Sway/assets/**` (entire assets dir)

- [ ] **Step 1: Copy verbatim-reusable scripts and assets**

```bash
mkdir -p ~/Fedora-Sway/install-scripts
cp /tmp/Fedora-Hyprland/install-scripts/Global_functions.sh ~/Fedora-Sway/install-scripts/
for s in fonts sddm sddm_theme gtk_themes bluetooth thunar thunar_default zsh zsh_pokemon nvidia rog InputGroup temp-monitor disk-monitor battery-monitor; do
  cp "/tmp/Fedora-Hyprland/install-scripts/$s.sh" ~/Fedora-Sway/install-scripts/
done
cp -r /tmp/Fedora-Hyprland/assets ~/Fedora-Sway/
```

- [ ] **Step 2: Create `copr.sh` (drop the Hyprland COPR)**

Copy `/tmp/Fedora-Hyprland/install-scripts/copr.sh`, then remove the `sdegler/hyprland` line from the `COPR_REPOS` array (Sway is in Fedora main; swaync/wallust/nwg-displays/terminal COPRs stay). Keep everything else identical.

```bash
cp /tmp/Fedora-Hyprland/install-scripts/copr.sh ~/Fedora-Sway/install-scripts/copr.sh
sed -i '/sdegler\/hyprland/d' ~/Fedora-Sway/install-scripts/copr.sh
```

- [ ] **Step 3: Validate**

Run: `for f in ~/Fedora-Sway/install-scripts/*.sh; do bash -n "$f" || echo "SYNTAX FAIL: $f"; done`
Expected: no output (all parse).
Run: `grep -c hyprland ~/Fedora-Sway/install-scripts/copr.sh`
Expected: `0`

- [ ] **Step 4: Commit**

```bash
cd ~/Fedora-Sway && git add -A && git commit -m "feat(installer): add reusable support scripts and COPR (sway, no hypr COPR)"
```

---

### Task 2: `00-sway-pkgs.sh` (package list)

**Files:**
- Create: `~/Fedora-Sway/install-scripts/00-sway-pkgs.sh`

- [ ] **Step 1: Write the package script**

Base it on `/tmp/Fedora-Hyprland/install-scripts/00-hypr-pkgs.sh` (keep the WARNING/source/loop boilerplate below the arrays verbatim). Replace the package arrays with:

```bash
# add packages wanted here
Extra=(

)

# packages needed (shared wlroots tooling — unchanged from upstream where possible)
sway_package=(
  bc
  curl
  findutils
  gawk
  git
  grim
  gvfs
  gvfs-mtp
  hyprpolkitagent
  ImageMagick
  inxi
  jq
  kitty
  kvantum
  nano
  network-manager-applet
  openssl
  pamixer
  pavucontrol
  pipewire-alsa
  pipewire-utils
  playerctl
  python3-requests
  python3-pip
  python3-pyquery
  qt5ct
  qt6ct
  qt6-qtsvg
  rofi-wayland
  slurp
  swappy
  unzip
  waybar
  wget2
  wl-clipboard
  wlogout
  xdg-user-dirs
  xdg-utils
  yad
)

# can be deleted, but dotfiles may not work fully
sway_package_2=(
  brightnessctl
  btop
  cava
  loupe
  fastfetch
  gnome-system-monitor
  mousepad
  mpv
  mpv-mpris
  nvtop
  qalculate-gtk
)

copr_packages=(
  nwg-displays
  cliphist
  nwg-look
  SwayNotificationCenter
  swww
  wallust
)

# conflicts to remove
uninstall=(
  aylurs-gtk-shell
  dunst
  mako
)
```

Then keep the upstream boilerplate, but rename the install loop variables from `hypr_package*` to `sway_package*`:

```bash
for PKG1 in "${sway_package[@]}" "${sway_package_2[@]}" "${copr_packages[@]}" "${Extra[@]}"; do
  install_package "$PKG1" "$LOG"
done
```

- [ ] **Step 2: Validate**

Run: `bash -n ~/Fedora-Sway/install-scripts/00-sway-pkgs.sh && echo OK`
Expected: `OK`
Run: `grep -c 'rofi-wayland' ~/Fedora-Sway/install-scripts/00-sway-pkgs.sh`
Expected: `1`

- [ ] **Step 3: Commit**

```bash
cd ~/Fedora-Sway && git add -A && git commit -m "feat(installer): add 00-sway-pkgs package list"
```

---

### Task 3: `sway.sh` and `wlr-portal.sh` (WM + portal install)

**Files:**
- Create: `~/Fedora-Sway/install-scripts/sway.sh`
- Create: `~/Fedora-Sway/install-scripts/wlr-portal.sh`

- [ ] **Step 1: Write `sway.sh`**

Mirror `/tmp/Fedora-Hyprland/install-scripts/hyprland.sh` boilerplate (SCRIPT_DIR/source Global_functions/LOG), replace the `hypr` array:

```bash
sway=(
    sway
    swaybg
    swayidle
    swaylock-effects
    wlsunset
    swww
)
```

Rename the loop to iterate `"${sway[@]}"` and update log text "Installing Sway packages".

- [ ] **Step 2: Write `wlr-portal.sh`**

Mirror `/tmp/Fedora-Hyprland/install-scripts/xdph.sh` boilerplate, install `xdg-desktop-portal-wlr` (and `xdg-desktop-portal-gtk` for file pickers). Package array:

```bash
portal=(
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
)
```

- [ ] **Step 3: Validate**

Run: `bash -n ~/Fedora-Sway/install-scripts/sway.sh && bash -n ~/Fedora-Sway/install-scripts/wlr-portal.sh && echo OK`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
cd ~/Fedora-Sway && git add -A && git commit -m "feat(installer): add sway.sh and wlr-portal.sh"
```

---

### Task 4: `dotfiles-main.sh` and `02-Final-Check.sh`

**Files:**
- Create: `~/Fedora-Sway/install-scripts/dotfiles-main.sh`
- Create: `~/Fedora-Sway/install-scripts/02-Final-Check.sh`

- [ ] **Step 1: Write `dotfiles-main.sh`**

Copy `/tmp/Fedora-Hyprland/install-scripts/dotfiles-main.sh`, replace all `Hyprland-Dots` with `Sway-Dots` and the clone URL with `https://github.com/seyboo/Sway-Dots`:

```bash
printf "${NOTE} Cloning and Installing ${SKY_BLUE}KooL-style Sway Dots${RESET}....\n"
if [ -d Sway-Dots ]; then
  cd Sway-Dots
  git stash && git pull
  chmod +x copy.sh
  ./copy.sh
else
  if git clone --depth=1 https://github.com/seyboo/Sway-Dots; then
    cd Sway-Dots || exit 1
    chmod +x copy.sh
    ./copy.sh
  else
    echo -e "$ERROR Can't download Sway-Dots. Check your internet connection"
  fi
fi
```

- [ ] **Step 2: Write `02-Final-Check.sh`**

Copy `/tmp/Fedora-Hyprland/install-scripts/02-Final-Check.sh`, change the essential-package check list so it verifies `sway`, `swaybg`, `swayidle`, `waybar`, `swww`, `rofi-wayland`, `SwayNotificationCenter` instead of hyprland packages. Keep the loop/reporting logic identical.

- [ ] **Step 3: Validate**

Run: `bash -n ~/Fedora-Sway/install-scripts/dotfiles-main.sh && bash -n ~/Fedora-Sway/install-scripts/02-Final-Check.sh && echo OK`
Expected: `OK`
Run: `grep -c 'Sway-Dots' ~/Fedora-Sway/install-scripts/dotfiles-main.sh`
Expected: `>=2`

- [ ] **Step 4: Commit**

```bash
cd ~/Fedora-Sway && git add -A && git commit -m "feat(installer): dotfiles-main clones Sway-Dots; final check verifies sway pkgs"
```

---

### Task 5: `install.sh` (main TUI)

**Files:**
- Create: `~/Fedora-Sway/install.sh`

- [ ] **Step 1: Adapt `install.sh`**

Copy `/tmp/Fedora-Hyprland/install.sh` and make these exact edits:
- ASCII banner / whiptail titles: "Hyprland" → "Sway".
- In the options checklist: remove the `quickshell` and `xdph` entries; add `"wlr_portal" "Install xdg-desktop-portal-wlr (screen share)?" "OFF"`.
- In the execute sequence, replace `execute_script "00-hypr-pkgs.sh"` → `execute_script "00-sway-pkgs.sh"`, `execute_script "hyprland.sh"` → `execute_script "sway.sh"`.
- In the `case` loop: remove `quickshell)` and `xdph)` branches; add:
```bash
        wlr_portal)
            echo "${INFO} Installing ${SKY_BLUE}xdg-desktop-portal-wlr...${RESET}" | tee -a "$LOG"
            execute_script "wlr-portal.sh"
            ;;
```
- Final check: replace the `rpm -q hyprland` block with `rpm -q sway`.
- Default option vars at top: remove `quickshell` and `xdph`, add `wlr_portal="OFF"`.
- Remove the fastfetch `fedora.png` copy only if you keep assets/fastfetch (keep it; it's fine).

- [ ] **Step 2: Validate**

Run: `bash -n ~/Fedora-Sway/install.sh && echo OK`
Expected: `OK`
Run: `grep -cE 'hypr(land|ctl)' ~/Fedora-Sway/install.sh`
Expected: `0`

- [ ] **Step 3: Commit**

```bash
cd ~/Fedora-Sway && git add -A && git commit -m "feat(installer): main install.sh TUI for Sway"
```

---

### Task 6: `preset.sh`, `auto-install.sh`, `uninstall.sh`

**Files:**
- Create: `~/Fedora-Sway/preset.sh`, `~/Fedora-Sway/auto-install.sh`, `~/Fedora-Sway/uninstall.sh`

- [ ] **Step 1: Adapt each**

Copy the three upstream files; in `preset.sh` and `auto-install.sh` replace option keys `quickshell`/`xdph` with `wlr_portal`, and replace `00-hypr-pkgs`/`hyprland.sh` refs with `00-sway-pkgs`/`sway.sh`. In `uninstall.sh` swap the removed package names to the sway set (`sway swaybg swayidle swaylock-effects swww wlsunset`).

- [ ] **Step 2: Validate**

Run: `for f in preset auto-install uninstall; do bash -n ~/Fedora-Sway/$f.sh || echo FAIL $f; done`
Expected: no FAIL output.

- [ ] **Step 3: Commit**

```bash
cd ~/Fedora-Sway && git add -A && git commit -m "feat(installer): preset, auto-install, uninstall for Sway"
```

---

### Task 7: README + docs for `Fedora-Sway`

**Files:**
- Create: `~/Fedora-Sway/README.md`, `~/Fedora-Sway/LICENSE.md`, `~/Fedora-Sway/.editorconfig`

- [ ] **Step 1: Write README**

Write a README modeled on upstream: title "Fedora-Sway", what it installs, one-line install command (`git clone ... && cd Fedora-Sway && chmod +x install.sh && ./install.sh`), the Hyprland→Sway feature map table, and a prominent **Attribution** section crediting JaKooLit/Fedora-Hyprland and JaKooLit/Hyprland-Dots with links. Copy `LICENSE.md` from upstream and `.editorconfig`.

```bash
cp /tmp/Fedora-Hyprland/LICENSE.md ~/Fedora-Sway/LICENSE.md
cp /tmp/Fedora-Hyprland/.editorconfig ~/Fedora-Sway/.editorconfig
```

- [ ] **Step 2: Commit**

```bash
cd ~/Fedora-Sway && git add -A && git commit -m "docs: README, LICENSE, editorconfig with JaKooLit attribution"
```

---

## Phase 2 — Sway-Dots: scaffolding + verbatim copies + sway core config

### Task 8: Init `Sway-Dots`, copy WM-agnostic dirs verbatim

**Files:**
- Create repo: `~/Sway-Dots`
- Copy: `config/{btop,cava,fastfetch,ghostty,kitty,Kvantum,qt5ct,qt6ct,swappy,wezterm}`, `wallpapers/`, `assets/`

- [ ] **Step 1: Scaffold and copy**

```bash
mkdir -p ~/Sway-Dots/config && cd ~/Sway-Dots && git init
for d in btop cava fastfetch ghostty kitty Kvantum qt5ct qt6ct swappy wezterm; do
  cp -r "/tmp/Hyprland-Dots/config/$d" ~/Sway-Dots/config/
done
cp -r /tmp/Hyprland-Dots/wallpapers ~/Sway-Dots/ 2>/dev/null || true
cp -r /tmp/Hyprland-Dots/assets ~/Sway-Dots/ 2>/dev/null || true
```

- [ ] **Step 2: Verify no Hyprland refs leaked into "clean" dirs**

Run: `grep -rl hypr ~/Sway-Dots/config 2>/dev/null`
Expected: no output. (If any appear, they were not truly clean — note them for Task 13.)

- [ ] **Step 3: Commit**

```bash
cd ~/Sway-Dots && git add -A && git commit -m "chore(dots): scaffold + copy WM-agnostic configs verbatim"
```

---

### Task 9: Sway main config + modular includes

**Files:**
- Create: `~/Sway-Dots/config/sway/config`
- Create: `~/Sway-Dots/config/sway/configs/{Keybinds,Startup_Apps,ENVariables,SystemSettings,WindowRules}.conf`
- Create: `~/Sway-Dots/config/sway/UserConfigs/{UserKeybinds,UserSettings,Startup_Apps,WindowRules,01-UserDefaults}.conf`
- Create: `~/Sway-Dots/config/sway/outputs` (nwg-displays target), `~/Sway-Dots/config/sway/workspaces`

The sway config mirrors the upstream modular structure (defaults in `configs/`, user overrides in `UserConfigs/`) using sway `include`.

- [ ] **Step 1: Write `config/sway/config` (loader)**

```
# Sway main config — KooL-style Sway-Dots (translated from JaKooLit Hyprland-Dots)
set $mainMod Mod4
set $term kitty
set $files thunar
set $scriptsDir $HOME/.config/sway/scripts
set $UserScripts $HOME/.config/sway/UserScripts

include $HOME/.config/sway/configs/ENVariables.conf
include $HOME/.config/sway/configs/SystemSettings.conf
include $HOME/.config/sway/configs/Keybinds.conf
include $HOME/.config/sway/configs/WindowRules.conf
include $HOME/.config/sway/configs/Startup_Apps.conf
include $HOME/.config/sway/UserConfigs/UserSettings.conf
include $HOME/.config/sway/UserConfigs/UserKeybinds.conf
include $HOME/.config/sway/UserConfigs/WindowRules.conf
include $HOME/.config/sway/UserConfigs/Startup_Apps.conf
include $HOME/.config/sway/UserConfigs/01-UserDefaults.conf
include $HOME/.config/sway/outputs
include $HOME/.config/sway/workspaces
```

- [ ] **Step 2: Write `configs/SystemSettings.conf`** (translate input/general from upstream)

```
# Input — translated from Hyprland configs/SystemSettings.conf
input * {
    xkb_layout us
    repeat_rate 50
    repeat_delay 300
    accel_profile flat
    natural_scroll enabled
    tap enabled
    dwt enabled
    middle_emulation disabled
}
input type:keyboard {
    xkb_numlock enabled
}
focus_follows_mouse yes
default_border pixel 2
default_floating_border normal
smart_borders on
gaps inner 5
gaps outer 5
# Sway has no blur/animation/rounding — intentionally omitted (see spec feature gaps)
```

- [ ] **Step 3: Write `configs/ENVariables.conf`** (translate, set desktop to sway)

```
# Environment — translated from Hyprland ENVariables.conf
set $DOTS_VERSION 2.3.20-sway
exec_always systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP
exec_always dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
# GDK_BACKEND/QT_QPA_PLATFORM/CLUTTER_BACKEND set via exec environment in Startup or login; sway sets XDG_CURRENT_DESKTOP=sway automatically
```

- [ ] **Step 4: Write `configs/Keybinds.conf`** — full translation of the upstream keybinds (see mapping table below)

```
# Keybinds — translated from JaKooLit Hyprland configs/Keybinds.conf
# Apps / launchers
bindsym $mainMod+d exec pkill rofi || rofi -show drun -modi drun,filebrowser,run,window
bindsym $mainMod+b exec xdg-open "https://"
bindsym $mainMod+Return exec $term
bindsym $mainMod+e exec $files

# Features
bindsym $mainMod+t exec $scriptsDir/ThemeChanger.sh
bindsym $mainMod+h exec $scriptsDir/KeyHints.sh
bindsym $mainMod+Alt+r exec $scriptsDir/Refresh.sh
bindsym $mainMod+Alt+e exec $scriptsDir/RofiEmoji.sh
bindsym $mainMod+s exec $scriptsDir/RofiSearch.sh
bindsym $mainMod+Ctrl+s exec rofi -show window
bindsym $mainMod+Shift+g exec $scriptsDir/GameMode.sh
bindsym $mainMod+Alt+v exec $scriptsDir/ClipManager.sh
bindsym $mainMod+Ctrl+r exec $scriptsDir/RofiThemeSelector.sh
bindsym $mainMod+w exec $UserScripts/WallpaperSelect.sh
bindsym $mainMod+Shift+w exec $UserScripts/WallpaperEffects.sh
bindsym Ctrl+Alt+w exec $UserScripts/WallpaperRandom.sh
bindsym $mainMod+Shift+m exec $UserScripts/RofiBeats.sh
bindsym $mainMod+Alt+c exec $UserScripts/RofiCalc.sh
bindsym $mainMod+Shift+k exec $scriptsDir/KeyBinds.sh
bindsym $mainMod+n exec $scriptsDir/Nightlight.sh toggle

# Window management
bindsym $mainMod+q kill
bindsym $mainMod+Shift+f fullscreen
bindsym $mainMod+space floating toggle
bindsym $mainMod+Shift+space focus mode_toggle
bindsym $mainMod+Shift+Return exec $scriptsDir/Dropterminal.sh $term
bindsym $mainMod+p focus parent
bindsym Ctrl+Alt+Delete exit
bindsym Ctrl+Alt+l exec $scriptsDir/LockScreen.sh
bindsym Ctrl+Alt+p exec $scriptsDir/Wlogout.sh
bindsym $mainMod+Shift+n exec swaync-client -t -sw
bindsym $mainMod+Shift+e exec $scriptsDir/Kool_Quick_Settings.sh

# Layout (master/dwindle → sway splits + tabbed/stacked)
bindsym $mainMod+Alt+l exec $scriptsDir/ChangeLayout.sh
bindsym $mainMod+Shift+i split toggle
bindsym $mainMod+g layout tabbed
bindsym $mainMod+Shift+g layout toggle split tabbed stacking

# Focus (arrows)
bindsym $mainMod+Left focus left
bindsym $mainMod+Right focus right
bindsym $mainMod+Up focus up
bindsym $mainMod+Down focus down
# Move
bindsym $mainMod+Ctrl+Left move left
bindsym $mainMod+Ctrl+Right move right
bindsym $mainMod+Ctrl+Up move up
bindsym $mainMod+Ctrl+Down move down
# Resize
bindsym $mainMod+Shift+Left resize shrink width 50px
bindsym $mainMod+Shift+Right resize grow width 50px
bindsym $mainMod+Shift+Up resize shrink height 50px
bindsym $mainMod+Shift+Down resize grow height 50px

# Cycle
bindsym Alt+Tab focus next
bindsym $mainMod+Tab workspace next
bindsym $mainMod+Shift+Tab workspace prev

# Workspaces 1-10
bindsym $mainMod+1 workspace number 1
bindsym $mainMod+2 workspace number 2
bindsym $mainMod+3 workspace number 3
bindsym $mainMod+4 workspace number 4
bindsym $mainMod+5 workspace number 5
bindsym $mainMod+6 workspace number 6
bindsym $mainMod+7 workspace number 7
bindsym $mainMod+8 workspace number 8
bindsym $mainMod+9 workspace number 9
bindsym $mainMod+0 workspace number 10
bindsym $mainMod+Shift+1 move container to workspace number 1
bindsym $mainMod+Shift+2 move container to workspace number 2
bindsym $mainMod+Shift+3 move container to workspace number 3
bindsym $mainMod+Shift+4 move container to workspace number 4
bindsym $mainMod+Shift+5 move container to workspace number 5
bindsym $mainMod+Shift+6 move container to workspace number 6
bindsym $mainMod+Shift+7 move container to workspace number 7
bindsym $mainMod+Shift+8 move container to workspace number 8
bindsym $mainMod+Shift+9 move container to workspace number 9
bindsym $mainMod+Shift+0 move container to workspace number 10
# Silent move (sway: move without follow — same cmd, no auto-focus)
bindsym $mainMod+Ctrl+bracketleft move container to workspace prev
bindsym $mainMod+Ctrl+bracketright move container to workspace next
# Special workspace → sway scratchpad
bindsym $mainMod+u scratchpad show
bindsym $mainMod+Shift+u move scratchpad
# Scroll workspaces
bindsym $mainMod+period workspace next
bindsym $mainMod+comma workspace prev

# Move workspace to output (Hyprland F9-F12)
bindsym $mainMod+Ctrl+F9 move workspace to output left
bindsym $mainMod+Ctrl+F10 move workspace to output right
bindsym $mainMod+Ctrl+F11 move workspace to output up
bindsym $mainMod+Ctrl+F12 move workspace to output down

# Mouse drag
floating_modifier $mainMod normal

# Media / hardware keys
bindsym --locked XF86AudioRaiseVolume exec $scriptsDir/Volume.sh --inc
bindsym --locked XF86AudioLowerVolume exec $scriptsDir/Volume.sh --dec
bindsym --locked XF86AudioMute exec $scriptsDir/Volume.sh --toggle
bindsym --locked XF86AudioMicMute exec $scriptsDir/Volume.sh --toggle-mic
bindsym --locked XF86MonBrightnessUp exec $scriptsDir/Brightness.sh --inc
bindsym --locked XF86MonBrightnessDown exec $scriptsDir/Brightness.sh --dec
bindsym --locked XF86AudioPlay exec $scriptsDir/MediaCtrl.sh --pause
bindsym --locked XF86AudioNext exec $scriptsDir/MediaCtrl.sh --nxt
bindsym --locked XF86AudioPrev exec $scriptsDir/MediaCtrl.sh --prv
bindsym --locked XF86AudioStop exec $scriptsDir/MediaCtrl.sh --stop

# Screenshots
bindsym Print exec $scriptsDir/ScreenShot.sh --now
bindsym $mainMod+Print exec $scriptsDir/ScreenShot.sh --now
bindsym $mainMod+Shift+Print exec $scriptsDir/ScreenShot.sh --area
bindsym Alt+Print exec $scriptsDir/ScreenShot.sh --active
bindsym $mainMod+Shift+s exec $scriptsDir/ScreenShot.sh --swappy
```

> **Translation notes for the engineer (intentional parity gaps):** Hyprland `group`/`changegroupactive` → sway tabbed/stacked containers (no per-window group manager); `master` layout has no sway equivalent → mapped to default tiling + `ChangeLayout.sh` cycling split/tabbed/stacking; `zoom`/`cursor:zoom_factor` → no sway equivalent, omitted; `toggle blur`/`animations menu`/`active opacity` → omitted (sway lacks). These omissions are per the spec "Feature gaps" section.

- [ ] **Step 5: Write `configs/Startup_Apps.conf`** (translate exec-once → exec_always/exec)

```
# Startup — translated from Hyprland Startup_Apps.conf
exec swww-daemon --format xrgb
exec $scriptsDir/Polkit.sh
exec nm-applet --indicator
exec swaync
exec waybar
exec wl-paste --type text --watch cliphist store
exec wl-paste --type image --watch cliphist store
exec $scriptsDir/Nightlight.sh init
exec swayidle -w \
  timeout 540 'notify-send -i $HOME/.config/swaync/images/ja.png " You are idle!"' \
  timeout 600 '$HOME/.config/sway/scripts/LockScreen.sh' \
  before-sleep 'loginctl lock-session'
```

- [ ] **Step 6: Write `configs/WindowRules.conf`** (translate `windowrule`/`windowrulev2` → `for_window`)

Translate the upstream `configs/WindowRules.conf` float/size/workspace rules. Example mappings (apply across the whole upstream file):
```
for_window [app_id="pavucontrol"] floating enable
for_window [app_id="blueman-manager"] floating enable
for_window [app_id="nm-connection-editor"] floating enable
for_window [app_id="qalculate-gtk"] floating enable
for_window [title="^(Picture-in-Picture)$"] floating enable, sticky enable
for_window [app_id="^(thunar)$"] floating enable
# inhibit idle for fullscreen video
for_window [app_id="mpv"] inhibit_idle fullscreen
```
Read `/tmp/Hyprland-Dots/config/hypr/configs/WindowRules.conf` and convert each rule: `class`→`app_id` (wayland) or `class` (xwayland), `windowrule = float, X` → `for_window [...] floating enable`.

- [ ] **Step 7: Write empty/minimal UserConfigs override stubs + nwg-displays targets**

```bash
mkdir -p ~/Sway-Dots/config/sway/UserConfigs
for f in UserKeybinds UserSettings Startup_Apps WindowRules 01-UserDefaults; do
  printf '# User overrides — add your own here (not touched by updates)\n' > ~/Sway-Dots/config/sway/UserConfigs/$f.conf
done
printf 'set $term kitty\nset $files thunar\n' > ~/Sway-Dots/config/sway/UserConfigs/01-UserDefaults.conf
# nwg-displays writes these; ship sane defaults
printf 'output * scale 1\n' > ~/Sway-Dots/config/sway/outputs
printf '# workspace-to-output assignments (nwg-displays writes here)\n' > ~/Sway-Dots/config/sway/workspaces
```

- [ ] **Step 8: Validate config syntax**

`sway -C` requires sway. In the VM (or any host with sway installed):
Run: `sway -C ~/Sway-Dots/config/sway/config`
Expected: exits 0, no "Error on line" output. (On a host without sway, defer to the VM smoke test in Task 15; at minimum verify no obvious typos.)

- [ ] **Step 9: Commit**

```bash
cd ~/Sway-Dots && git add -A && git commit -m "feat(sway): main config + modular keybinds/settings/startup/windowrules"
```

---

### Task 10: Lockscreen + idle + nightlight glue

**Files:**
- Create: `~/Sway-Dots/config/sway/scripts/LockScreen.sh`
- Create: `~/Sway-Dots/config/sway/scripts/Nightlight.sh`
- Create: `~/Sway-Dots/config/swaylock/config`

- [ ] **Step 1: Write `swaylock/config`** (plain swaylock — Fedora main repo, NOT swaylock-effects)

> NOTE: We install plain `swaylock` (main repo). `swaylock-effects`-only options
> (`screenshots`, `effect-blur`, `effect-vignette`, `fade-in`, `clock`) are NOT
> supported — do not add them. Use only base swaylock options below.

```
# swaylock (plain) — replaces hyprlock
color=1e1e2e
indicator
indicator-radius=120
indicator-thickness=12
ring-color=1e1e2e
ring-ver-color=89b4fa
ring-wrong-color=f38ba8
key-hl-color=89b4fa
line-color=00000000
inside-color=11111b88
inside-ver-color=11111b88
inside-wrong-color=f38ba8
separator-color=00000000
text-color=cdd6f4
text-ver-color=cdd6f4
```

- [ ] **Step 2: Write `scripts/LockScreen.sh`**

```bash
#!/bin/bash
# Lock screen — swaylock-effects (replaces hyprlock LockScreen.sh)
pidof swaylock || swaylock -C "$HOME/.config/swaylock/config"
```

- [ ] **Step 3: Write `scripts/Nightlight.sh`** (wlsunset, replaces Hyprsunset.sh)

```bash
#!/bin/bash
# Night light via wlsunset (replaces Hyprsunset.sh)
case "$1" in
  init)   pgrep -x wlsunset >/dev/null || wlsunset -t 4000 -T 6500 & ;;
  toggle) if pgrep -x wlsunset >/dev/null; then pkill -x wlsunset; notify-send "Night light off"; else wlsunset -t 4000 -T 6500 & notify-send "Night light on"; fi ;;
esac
```

- [ ] **Step 4: Validate + chmod**

Run: `chmod +x ~/Sway-Dots/config/sway/scripts/{LockScreen,Nightlight}.sh; shellcheck ~/Sway-Dots/config/sway/scripts/LockScreen.sh ~/Sway-Dots/config/sway/scripts/Nightlight.sh`
Expected: no errors (warnings acceptable).

- [ ] **Step 5: Commit**

```bash
cd ~/Sway-Dots && git add -A && git commit -m "feat(sway): swaylock config + LockScreen/Nightlight glue"
```

---

## Phase 3 — Script translation (hyprctl → swaymsg)

### Task 11: Translate the scripts directory (`config/hypr/scripts` → `config/sway/scripts`)

**Files:**
- Create: `~/Sway-Dots/config/sway/scripts/*` (translated from `/tmp/Hyprland-Dots/config/hypr/scripts/*`)
- Create: `~/Sway-Dots/config/sway/UserScripts/*` (translated from upstream `UserScripts`)

**Dispatcher mapping table (apply consistently):**

| Hyprland | Sway |
|---|---|
| `hyprctl dispatch exec X` | `swaymsg exec X` |
| `hyprctl dispatch killactive` | `swaymsg kill` |
| `hyprctl dispatch fullscreen` | `swaymsg fullscreen toggle` |
| `hyprctl dispatch togglefloating` | `swaymsg floating toggle` |
| `hyprctl dispatch workspace N` | `swaymsg workspace number N` |
| `hyprctl dispatch movetoworkspace N` | `swaymsg move container to workspace number N` |
| `hyprctl clients -j` | `swaymsg -t get_tree` |
| `hyprctl activewindow -j` | `swaymsg -t get_tree \| jq '.. \| select(.focused?==true)'` |
| `hyprctl monitors -j` | `swaymsg -t get_outputs` |
| `hyprctl -j getoption X` | (no equivalent — handle per script / drop) |
| `hyprctl keyword cursor:zoom_factor` | (drop — sway has no zoom) |
| `hyprctl dispatch dpms on/off` | `swaymsg "output * dpms on/off"` |
| `hyprctl reload` | `swaymsg reload` |
| `$mainMod`/dispatch in config refs | n/a (handled in Keybinds.conf) |
| wallpaper `swww` calls | unchanged (swww works on sway) |

**Per-script disposition** (translate unless marked):

| Script | Action |
|---|---|
| Refresh.sh, RefreshNoWaybar.sh | translate: `hyprctl reload`→`swaymsg reload`; keep waybar/swaync/swww restart logic |
| ScreenShot.sh | translate: replace `hyprctl` active-window geometry with `swaymsg -t get_tree` + `grim`/`slurp`; keep grim/swappy paths |
| Volume.sh, Brightness.sh, BrightnessKbd.sh, MediaCtrl.sh, AirplaneMode.sh | mostly WM-agnostic (pamixer/brightnessctl/playerctl) — copy, strip any `hyprctl notify` → `notify-send` |
| ThemeChanger.sh, DarkLight.sh, Kitty_themes.sh | translate wallust/theme apply; replace `hyprctl reload`→`swaymsg reload` |
| WallustSwww.sh | translate: swww unchanged; `hyprctl` reload→`swaymsg reload` |
| Wlogout.sh | translate layout flags; uses wlogout (WM-agnostic) — copy, drop hypr-specific args |
| WaybarScripts.sh, WaybarStyles.sh, WaybarLayout.sh, WaybarCava.sh | copy; replace any `hyprctl` calls; waybar restart via `pkill -SIGUSR2 waybar` or restart |
| Dropterminal.sh | rewrite using sway scratchpad: `swaymsg` scratchpad show/move + a marked terminal |
| ChangeLayout.sh | rewrite: cycle `swaymsg layout` split/tabbed/stacking (replaces master/dwindle) |
| ChangeBlur.sh, Animations.sh, GameMode.sh, OverviewToggle.sh, RainbowBorders* | **drop or stub** (no sway equivalent for blur/anim/overview); GameMode reduced to "disable idle + notify" |
| Polkit.sh, Polkit-NixOS.sh | rewrite Polkit.sh to launch `lxqt-policykit-agent` (we install `lxqt-policykit` from main repo instead of hyprpolkitagent): `pgrep -x lxqt-policykit- >/dev/null || /usr/bin/lxqt-policykit-agent &`. Drop the NixOS variant |
| PortalHyprland.sh | **replace** with `PortalWlr.sh` (starts xdg-desktop-portal-wlr) |
| Hypridle.sh, Hyprsunset.sh | **replace** by Task 10 (swayidle in Startup, Nightlight.sh) — drop these |
| LockScreen.sh | already written in Task 10 — skip |
| KeyHints.sh, KeyBinds.sh, keybinds_parser.py, KeybindsLayoutInit.sh | translate the parser to read `config/sway/configs/Keybinds.conf` (`bindsym` lines) instead of Hyprland `bind` lines |
| RofiEmoji.sh, RofiSearch.sh, RofiThemeSelector*.sh, ClipManager.sh, Kool_Quick_Settings.sh, KillActiveProcess.sh, Sounds.sh, KeyboardLayout.sh, TouchPad.sh | copy; replace `hyprctl` calls (KillActiveProcess uses `hyprctl activewindow`→`swaymsg -t get_tree`; KeyboardLayout/TouchPad use `swaymsg input` instead of `hyprctl keyword`) |
| MonitorProfiles.sh, sddm_wallpaper.sh, update_WindowRules.sh, UserConfigsSwitcher.sh | translate paths hypr→sway; MonitorProfiles uses `swaymsg -t get_outputs` |
| Tak0-*.sh | drop (Hyprland per-window keyboard-layout hack; sway handles via `input` per-device) |
| UptimeNixOS.sh, Distro_update.sh, KooLsDotsUpdate.sh | copy; fix repo name Hyprland-Dots→Sway-Dots |
| UserScripts/Wallpaper*.sh, RofiBeats/RofiCalc/Weather* , ZshChangeTheme | copy; swww unchanged; replace any `hyprctl reload`→`swaymsg reload` |

> **Granularity for execution:** treat each script (or small batch of WM-agnostic copies) as one sub-step: read the upstream file, apply the mapping table, write to the sway path, `shellcheck`, `chmod +x`. Commit in batches of ~8 scripts.

- [ ] **Step 1: Copy WM-agnostic scripts unchanged, then chmod**

Identify scripts with zero `hyprctl`/`hypr` references and copy them directly:
```bash
mkdir -p ~/Sway-Dots/config/sway/scripts ~/Sway-Dots/config/sway/UserScripts
for f in /tmp/Hyprland-Dots/config/hypr/scripts/*; do
  base=$(basename "$f")
  if ! grep -qil hypr "$f"; then cp "$f" ~/Sway-Dots/config/sway/scripts/"$base"; fi
done
```

- [ ] **Step 2: Translate hyprctl-bearing scripts** per the table above (one per sub-step; this is the bulk of the work).

- [ ] **Step 3: Drop the no-equivalent scripts** (do NOT create: ChangeBlur.sh, Animations.sh, OverviewToggle.sh, RainbowBorders*, Hypridle.sh, Hyprsunset.sh, Tak0-*.sh, Polkit-NixOS.sh, PortalHyprland.sh→replaced). Log the drop list in a `config/sway/scripts/README` so users know.

- [ ] **Step 4: Validate all scripts**

Run: `chmod +x ~/Sway-Dots/config/sway/scripts/* ~/Sway-Dots/config/sway/UserScripts/* 2>/dev/null; for f in ~/Sway-Dots/config/sway/scripts/*.sh ~/Sway-Dots/config/sway/UserScripts/*.sh; do shellcheck -S error "$f" || echo "SC FAIL: $f"; done`
Expected: no "SC FAIL".
Run: `grep -rl 'hyprctl' ~/Sway-Dots/config/sway/scripts ~/Sway-Dots/config/sway/UserScripts`
Expected: no output (all translated).

- [ ] **Step 5: Commit** (in batches during translation, final commit here)

```bash
cd ~/Sway-Dots && git add -A && git commit -m "feat(sway): translate scripts hyprctl→swaymsg; drop no-equivalent scripts"
```

---

## Phase 4 — Waybar / swaync / rofi / wlogout / wallust wiring

### Task 12: Waybar — sway modules

**Files:**
- Create: `~/Sway-Dots/config/waybar/**` (from `/tmp/Hyprland-Dots/config/waybar`)

- [ ] **Step 1: Copy waybar tree, then translate modules**

```bash
cp -r /tmp/Hyprland-Dots/config/waybar ~/Sway-Dots/config/
grep -rl 'hyprland/' ~/Sway-Dots/config/waybar
```
For every config JSON/JSONC: `"hyprland/workspaces"`→`"sway/workspaces"`, `"hyprland/window"`→`"sway/window"`, `"hyprland/language"`→`"sway/language"`. Add `"sway/mode"` and `"sway/scratchpad"` where a mode/scratchpad indicator fits. Remove `hyprland/submap` modules (no sway equivalent) or map to `sway/mode`.

- [ ] **Step 2: Validate JSON + no hypr refs**

Run: `for f in $(find ~/Sway-Dots/config/waybar -name '*.json*'); do jq -e . "$f" >/dev/null 2>&1 || echo "JSON FAIL: $f"; done`
Expected: no "JSON FAIL" (note: `.jsonc` with comments may need `// ` stripped before jq — if so, validate visually).
Run: `grep -rl 'hyprland/' ~/Sway-Dots/config/waybar`
Expected: no output.

- [ ] **Step 3: Commit**

```bash
cd ~/Sway-Dots && git add -A && git commit -m "feat(waybar): sway/workspaces + sway/window modules"
```

---

### Task 13: swaync, rofi, wlogout, wallust

**Files:**
- Create: `~/Sway-Dots/config/{swaync,rofi,wlogout,wallust}/**`

- [ ] **Step 1: Copy and fix stray hypr references**

```bash
for d in swaync rofi wlogout wallust; do cp -r "/tmp/Hyprland-Dots/config/$d" ~/Sway-Dots/config/; done
grep -rl hypr ~/Sway-Dots/config/{swaync,rofi,wlogout,wallust}
```
For each hit: replace `hyprctl reload`→`swaymsg reload`, `~/.config/hypr`→`~/.config/sway` paths, `wallust-hyprland.conf` reference → `wallust-sway.conf`. In `wallust/`: rename `templates`/output that targets hypr to target sway config (the wallust template that wrote Hyprland colors → write a sway-compatible include or waybar/swaylock colors).

- [ ] **Step 2: wallust template for sway**

Create `~/Sway-Dots/config/wallust/templates/` entry that outputs sway-usable colors (e.g. a `colors-sway.conf` with `client.focused` border colors) and wire `wallust.toml` to emit it. Remove the Hyprland color template.

- [ ] **Step 3: Validate**

Run: `grep -rl hypr ~/Sway-Dots/config/{swaync,rofi,wlogout,wallust}`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
cd ~/Sway-Dots && git add -A && git commit -m "feat(dots): swaync/rofi/wlogout/wallust wired for sway"
```

---

### Task 14: `copy.sh` (dotfiles installer) + README/attribution

**Files:**
- Create: `~/Sway-Dots/copy.sh`
- Create: `~/Sway-Dots/README.md`, `~/Sway-Dots/LICENSE.md`

- [ ] **Step 1: Adapt `copy.sh`**

Base on `/tmp/Hyprland-Dots/copy.sh`. Keep the backup-then-copy logic and helper functions. Change the config dir list it installs: replace `hypr` with `sway`; keep the WM-agnostic dirs; remove `ags`/`quickshell` (Hyprland overview deps). Ensure it `chmod +x` the `config/sway/scripts` and `UserScripts`. Update prompts "Hyprland"→"Sway".

- [ ] **Step 2: Write README + attribution, copy LICENSE**

```bash
cp /tmp/Hyprland-Dots/LICENSE.md ~/Sway-Dots/LICENSE.md
```
README: "Sway-Dots — KooL-style Sway rice translated from JaKooLit/Hyprland-Dots", feature map, the dropped-features list (blur/animations/overview/zoom), and prominent attribution + link to JaKooLit.

- [ ] **Step 3: Validate**

Run: `bash -n ~/Sway-Dots/copy.sh && shellcheck -S error ~/Sway-Dots/copy.sh && echo OK`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
cd ~/Sway-Dots && git add -A && git commit -m "feat(dots): copy.sh installer + README/LICENSE with attribution"
```

---

## Phase 5 — Integration test + publish

### Task 15: VM smoke test

- [ ] **Step 1: Provision a Fedora VM** (Boxes/virt-manager, 3D accel ON). Enable testing against local repos: either push to GitHub first (Task 16) or `scp` both repos into the VM and point `dotfiles-main.sh` at the local path.

- [ ] **Step 2: Run installer**

```bash
cd ~/Fedora-Sway && chmod +x install.sh && ./install.sh
# select: gtk_themes, bluetooth, thunar, wlr_portal, sddm, zsh, dots
```
Expected: completes without fatal errors; `rpm -q sway` succeeds; `02-Final-Check.sh` reports essentials installed.

- [ ] **Step 3: Boot Sway session via SDDM and verify each subsystem**

Checklist (each must work):
- [ ] Sway starts, waybar visible
- [ ] `$mainMod+Return` opens kitty; `$mainMod+d` opens rofi
- [ ] swww wallpaper present; `$mainMod+w` wallpaper select works
- [ ] `$mainMod+t` ThemeChanger applies wallust colors; `swaymsg reload` succeeds
- [ ] Screenshots (`Print`, `$mainMod+Shift+Print` area, swappy) work
- [ ] `Ctrl+Alt+l` locks (swaylock-effects); swayidle locks after timeout
- [ ] swaync notifications (`$mainMod+Shift+n` panel)
- [ ] `Ctrl+Alt+p` wlogout menu
- [ ] Volume/brightness/media keys
- [ ] nwg-displays writes `~/.config/sway/outputs` and reload applies it
- [ ] `xdg-desktop-portal-wlr` screen share (test in OBS or browser)

- [ ] **Step 4: Fix-forward** any failures (re-enter the relevant task), commit fixes.

- [ ] **Step 5: Record results** in `~/Fedora-Sway/docs/superpowers/plans/2026-06-13-fedora-sway.md` test log or a new `TESTING.md`.

---

### Task 16: Publish to GitHub (`seyboo`)

- [ ] **Step 1: Create remotes and push** (requires `gh auth login` or an authenticated `gh`)

```bash
cd ~/Fedora-Sway && gh repo create seyboo/Fedora-Sway --public --source=. --remote=origin --push
cd ~/Sway-Dots && gh repo create seyboo/Sway-Dots --public --source=. --remote=origin --push
```

- [ ] **Step 2: Verify** clone URL in `Fedora-Sway/install-scripts/dotfiles-main.sh` matches the pushed `Sway-Dots` URL.

Run: `grep 'github.com/seyboo/Sway-Dots' ~/Fedora-Sway/install-scripts/dotfiles-main.sh`
Expected: match.

- [ ] **Step 3: Final commit/tag if desired.**

---

## Self-Review notes

- **Spec coverage:** installer (Tasks 1–7), verbatim copies (Task 8), config/sway core incl. swayidle/swaylock/swww (Tasks 9–10), 53-script translation (Task 11), waybar/swaync/rofi/wlogout/wallust (Tasks 12–13), copy.sh + attribution (Task 14), VM test (Task 15), GitHub publish (Task 16). All spec sections mapped.
- **Feature gaps** (animations/blur/rounding/zoom/overview) explicitly dropped in Tasks 9 & 11 with a user-facing drop list — matches spec.
- **Naming consistency:** `$mainMod` = `Mod4` throughout; scripts dir `$HOME/.config/sway/scripts`; dotfiles repo `Sway-Dots` everywhere.
- **Known soft spots to watch during execution:** (1) Hyprland `group` UX has no exact sway analog — tabbed/stacked is the agreed substitute. (2) wallust template rewrite (Task 13 Step 2) is the least mechanical step; budget extra time. (3) `.jsonc` waybar files may break `jq` due to comments — validate visually if so.
