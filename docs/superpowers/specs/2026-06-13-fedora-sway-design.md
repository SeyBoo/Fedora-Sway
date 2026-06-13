# Fedora-Sway — Design

**Date:** 2026-06-13
**Author:** seyboo (with Claude Code)
**Status:** Approved

## Goal

Replicate JaKooLit's `Fedora-Hyprland` installer + `Hyprland-Dots` ricing for the
**Sway** window manager on Fedora Linux. Full ricing parity, achieved by forking
and translating the upstream dotfiles rather than authoring from scratch.

Upstream sources:
- Installer: https://github.com/JaKooLit/Fedora-Hyprland
- Dotfiles: https://github.com/JaKooLit/Hyprland-Dots

## Decisions (locked during brainstorming)

| Decision | Choice |
|---|---|
| Scope | Full ricing parity |
| Publish | Local repos + push to GitHub user `seyboo` |
| Dotfiles strategy | Fork & translate upstream (keep WM-agnostic, translate WM layer) |
| Feature gaps | Map to closest wlroots tool; drop what Sway cannot do |
| Repo layout | Two repos, mirroring upstream split |

## Architecture — two repos

### Repo 1: `Fedora-Sway` (Fedora-specific installer)

Direct analog of `Fedora-Hyprland`. Same whiptail TUI, preset system, COPR setup,
SDDM/nvidia/input-group/fonts/themes logic. Modular `install-scripts/` executed by
`install.sh`.

| Upstream file | Action |
|---|---|
| `install.sh` | Reword Hyprland→Sway. Drop `quickshell` + `xdph` options; replace with `wlr` portal option. Keep TUI, preset, SDDM, nvidia, input-group, dots flow. |
| `auto-install.sh`, `preset.sh`, `uninstall*.sh` | Reword, keep logic. |
| `install-scripts/copr.sh` | Drop `sdegler/hyprland` COPR. Keep `erikreider/SwayNotificationCenter`, `errornointernet/packages` (wallust), `tofik/nwg-shell` (nwg-displays), terminal COPRs. |
| `install-scripts/00-hypr-pkgs.sh` → `00-sway-pkgs.sh` | Swap WM package list (see map). Keep shared tooling (waybar, rofi, swaync, wlogout, wallust, swww, etc.). |
| `install-scripts/hyprland.sh` → `sway.sh` | Install `sway swaybg swayidle swaylock-effects wlsunset swww`. |
| `install-scripts/xdph.sh` → `wlr-portal.sh` | Install `xdg-desktop-portal-wlr`. |
| `install-scripts/dotfiles-main.sh` | Clone `https://github.com/seyboo/Sway-Dots` instead of Hyprland-Dots. |
| `Global_functions.sh`, `fonts.sh`, `sddm*.sh`, `gtk_themes.sh`, `zsh*.sh`, `bluetooth.sh`, `thunar*.sh`, `nvidia.sh`, `rog.sh`, `InputGroup.sh` | Mostly verbatim. |
| `install-scripts/02-Final-Check.sh` | Check for `sway` instead of `hyprland`. |
| `assets/` | Keep (fastfetch, zsh themes, gtk, Thunar, sddm). Swap fastfetch image refs if needed. |

**Package map (Hyprland → closest wlroots/Sway tool):**

| Hyprland | Sway replacement | Source |
|---|---|---|
| hyprland | sway | Fedora main |
| hypridle | swayidle | Fedora main |
| hyprlock | swaylock-effects | Fedora main |
| hyprpaper / swww | swww | COPR (errornointernet or equivalent) |
| hyprsunset | wlsunset | Fedora main |
| xdg-desktop-portal-hyprland | xdg-desktop-portal-wlr | Fedora main |
| hyprpolkitagent | hyprpolkitagent (WM-agnostic, keep) | COPR |

Sway core lives in Fedora main repos — **no COPR needed for the WM itself**.

### Repo 2: `Sway-Dots` (distro-agnostic dotfiles)

Fork of `Hyprland-Dots`. 636 files upstream; ~10 config dirs fully WM-agnostic.

**Copy verbatim (WM-agnostic):** `btop`, `cava`, `fastfetch`, `ghostty`, `kitty`,
`Kvantum`, `qt5ct`, `qt6ct`, `swappy`, `wezterm`.

**Translate `config/hypr` → `config/sway`:**
- `hyprland.conf` → `sway/config` — keybinds, `exec`/`exec-once`→`exec`/`exec_always`,
  input, env. Window rules → sway `for_window` criteria.
- `monitors.conf` → sway `output` blocks. nwg-displays supports sway and writes here.
- `hypridle.conf` → swayidle config (or systemd args).
- `hyprlock*.conf` → swaylock-effects config(s) (1080p / 2k variants).
- hyprpaper → swww (`swww-daemon` + `swww img`).
- Drop: animations, blur, rounded corners, per-window dim (Sway has none).

**Translate scripts (53 total, 41 call `hyprctl`):**
- `hyprctl dispatch <x>` → `swaymsg <x>` (dispatcher syntax mapped per command).
- `hyprctl clients` / `activewindow` → `swaymsg -t get_tree` / `get_workspaces`.
- Affected: Refresh, ScreenShot, Volume, ThemeChanger, WallustSwww, Wlogout,
  Waybar* scripts, RofiThemeSelector, TouchPad, etc.
- Drop or stub Hyprland-only scripts (PortalHyprland, hyprland-specific window rules).

**Waybar:**
- `hyprland/workspaces` → `sway/workspaces`.
- `hyprland/window` → `sway/window`.
- Add `sway/mode`, `sway/scratchpad`.
- Themes / styles / WaybarScripts copied; fix internal hyprctl calls.

**swaync, rofi, wlogout, wallust:** copy, fix stray hyprctl references.

**`copy.sh`:** adapt upstream copier — same backup-then-copy logic, sway paths,
list `sway` config dir instead of `hypr`.

**Attribution:** README credits JaKooLit; retain upstream `LICENSE.md` terms.

## Feature gaps (explicitly dropped)

Window animations, blur, rounded corners, per-window dimming. Sway is a tiling
wlroots compositor without these; everything else reaches functional parity.

## Build order

1. `Fedora-Sway` installer skeleton (TUI, COPR, package scripts, dotfiles-main).
2. `Sway-Dots`: verbatim WM-agnostic copies + `config/sway` core (config, swayidle,
   swaylock, swww).
3. Script translation (hyprctl → swaymsg across 53 scripts).
4. Waybar / swaync / rofi / wlogout theming wiring.
5. End-to-end test in a Fedora VM; iterate.

## Testing

- Shellcheck on all `.sh`.
- `sway --validate` (or `sway -C`) on translated config.
- VM smoke test: run installer, boot SDDM → Sway session, verify waybar, keybinds,
  screenshot, wallpaper, lock, idle, notifications, rofi, wlogout.

## Out of scope

- Non-Fedora distro installers (upstream Dots has `Distro-Hyprland.sh`; Sway-Dots
  stays Fedora-focused for now, structure permitting later expansion).
- Replicating Hyprland-only eye-candy.
