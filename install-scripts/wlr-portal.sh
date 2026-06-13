#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# XDG-Desktop-Portals (wlroots) #

portal=(
  xdg-desktop-portal-wlr
  xdg-desktop-portal-gtk
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_wlr-portal.log"

# XDG-DESKTOP-PORTAL-WLR
printf "${NOTE} Installing ${SKY_BLUE}xdg-desktop-portal-wlr${RESET}\n\n"
for portalpkg in "${portal[@]}"; do
  install_package "$portalpkg" "$LOG"
done

printf "\n%.0s" {1..2}
