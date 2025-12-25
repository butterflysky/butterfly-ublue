#!/bin/bash

set -ouex pipefail

### Add some repos
dnf5 -y copr enable lionheartp/Hyprland 
dnf5 -y copr enable erikreider/SwayNotificationCenter

dnf5 install -y \
  aquamarine \
  gnome-keyring \
  fuzzel \
  hyprcursor \
  hyprgraphics \
  hypridle \
  hyprland \
  hyprland-guiutils \
  hyprland-qt-support \
  hyprlang \
  hyprlock \
  hyprpaper \
  hyprpicker \
  hyprpolkitagent \
  hyprpwcenter \
  hyprqt6engine \
  hyprshutdown \
  hyprsunset \
  hyprsysteminfo \
  hyprtoolkit \
  hyprutils \
  hyprwayland-scanner \
  seahorse \
  SwayNotificationCenter \
  xdg-desktop-portal-hyprland \
  waybar wl-clipboard wofi

# these 3 aren't in the copr repo
  #clipvault \
  #hyprlauncher \
  #hyprtile \

dnf5 -y copr disable lionheartp/Hyprland
dnf5 -y copr disable erikreider/SwayNotificationCenter
