<div align="center">

# 🇫 Fedora-Sway

**KooL-style Sway rice installer for Fedora Linux**

A community translation of [JaKooLit](https://github.com/JaKooLit)'s
[`Fedora-Hyprland`](https://github.com/JaKooLit/Fedora-Hyprland) +
[`Hyprland-Dots`](https://github.com/JaKooLit/Hyprland-Dots) to the
[Sway](https://swaywm.org/) (wlroots) window manager.

</div>

---

## What it installs

- **WM core:** `sway`, `swaybg`, `swayidle`, `swaylock`, `swww`, `wlsunset`
- **Desktop:** `waybar`, `SwayNotificationCenter` (swaync), `rofi`, `wlogout`,
  `wallust` (dynamic theming), `nwg-displays`, `cliphist`
- **Theming:** GTK themes, Kvantum, qt5ct/qt6ct, fonts
- **Optional (whiptail menu):** SDDM login manager + theme, zsh + Oh-My-Zsh,
  Thunar, Bluetooth, NVIDIA configuration, ASUS ROG support, xdg-desktop-portal-wlr
- **Dotfiles:** pulls the companion [`Sway-Dots`](https://github.com/seyboo/Sway-Dots) repo

## Install

> Run a full system update and reboot first. On a VM, enable 3D acceleration.

```bash
git clone https://github.com/seyboo/Fedora-Sway.git
cd Fedora-Sway
chmod +x install.sh
./install.sh
```

Do **not** run as root. The script uses `sudo` where needed.

## Hyprland → Sway feature map

| Hyprland | Sway replacement | Source |
|---|---|---|
| hyprland | sway | Fedora main |
| hypridle | swayidle | Fedora main |
| hyprlock | swaylock | Fedora main |
| hyprpaper / swww | swww | COPR |
| hyprsunset | wlsunset | Fedora main |
| xdg-desktop-portal-hyprland | xdg-desktop-portal-wlr | Fedora main |
| hyprpolkitagent | lxqt-policykit | Fedora main |

Sway itself is in the Fedora main repos — no COPR is needed for the window
manager. COPRs are still used for `swww`, `wallust`, `nwg-displays`, and swaync.

## Dropped features

Sway is a minimal wlroots compositor and does **not** support some Hyprland
eye-candy. These are intentionally omitted:

- Window animations
- Blur
- Rounded corners
- Desktop overview (quickshell/AGS)
- Cursor zoom / magnifier

Everything else reaches functional parity.

## Attribution / Credits

This project is a **community Sway translation** of the work of
[**JaKooLit**](https://github.com/JaKooLit). All credit for the original
installer design, dotfiles, theming, and scripts goes to them:

- [JaKooLit/Fedora-Hyprland](https://github.com/JaKooLit/Fedora-Hyprland)
- [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots)

This repository is **not affiliated with or endorsed by** JaKooLit. It exists to
bring the same experience to Sway users. Please support the upstream author.

## License

See [`LICENSE.md`](LICENSE.md) (inherited from upstream).
