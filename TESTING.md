# Testing — Fedora-Sway

Tasks 1–14 are implemented and statically verified (syntax, include resolution,
script-reference cross-check, JSON sanity). The remaining verification is a live
VM smoke test (Task 15), which requires a Fedora VM with 3D acceleration — it
cannot be run headless.

## Static checks already passing

- All `install-scripts/*.sh` and root `*.sh` pass `bash -n`.
- No `hyprctl`/`hyprland` functional refs in installer or dotfiles code (only
  attribution/translation comments remain).
- `Sway-Dots/config/sway/config` include targets all resolve in-repo.
- Every script referenced by keybinds / startup / waybar / swaync / wlogout
  exists in `config/sway/scripts` or `config/sway/UserScripts`.
- All waybar JSON/JSONC configs parse.
- `swaylock` (plain), `rofi`, `lxqt-policykit` confirmed available in Fedora 44
  main repos; `swww`/`wallust`/`nwg-displays`/`SwayNotificationCenter` via COPR.

## Not yet done (needs a Fedora VM)

> **`sway -C` config validation** — sway is not installed on the build host.
> Run `sway -C ~/.config/sway/config` after the dotfiles are copied, or
> `sudo dnf install sway && sway -C Sway-Dots/config/sway/config` to validate.

## VM smoke-test checklist (Task 15)

1. Provision a Fedora VM (Boxes/virt-manager), enable 3D acceleration.
2. Make the local repos reachable: either push to GitHub first (Task 16) or copy
   both repos into the VM and point `install-scripts/dotfiles-main.sh` at the
   local `Sway-Dots` path.
3. `cd Fedora-Sway && chmod +x install.sh && ./install.sh`
   - select: gtk_themes, bluetooth, thunar, wlr_portal, sddm, zsh, dots
   - expect: completes without fatal errors; `rpm -q sway` succeeds;
     `02-Final-Check.sh` reports essentials installed.
4. Boot the Sway session via SDDM and verify each item:

- [ ] Sway starts, waybar visible
- [ ] `SUPER+Return` opens kitty; `SUPER+D` opens rofi
- [ ] swww wallpaper present; `SUPER+W` wallpaper select works
- [ ] `SUPER+T` ThemeChanger applies wallust colors; `swaymsg reload` succeeds
- [ ] Screenshots: `Print`, `SUPER+Shift+Print` (area), `SUPER+Shift+S` (swappy)
- [ ] `CTRL+ALT+L` locks (swaylock); swayidle locks after timeout
- [ ] swaync notifications; `SUPER+Shift+N` panel
- [ ] `CTRL+ALT+P` wlogout menu
- [ ] Volume / brightness / media keys
- [ ] waybar idle-inhibitor toggle + night-light (wlsunset) module
- [ ] lxqt-policykit auth prompt appears for a privileged action
- [ ] nwg-displays writes `~/.config/sway/outputs`; reload applies it
- [ ] `xdg-desktop-portal-wlr` screen share (OBS or browser)

5. Fix-forward any failures, commit, re-test.
