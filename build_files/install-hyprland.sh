#!/bin/bash

set -ouex pipefail

### Add some repos
dnf5 -y copr enable lionheartp/Hyprland 

dnf5 install -y \
  aquamarine \
  clipvault \
  gnome-keyring \
  hyprcursor \
  hyprgraphics \
  hypridle \
  hyprland \
  hyprland-guiutils \
  hyprland-qt-support \
  hyprlang \
  hyprlauncher \
  hyprlock \
  hyprpaper \
  hyprpicker \
  hyprpolkitagent \
  hyprpwcenter \
  hyprqt6engine \
  hyprshutdown \
  hyprsunset \
  hyprsysteminfo \
  hyprtile \
  hyprtoolkit \
  hyprutils \
  hyprwayland-scanner \
  mako \
  seahorse \
  xdg-desktop-portal-hyprland \
  waybar wl-clipboard wofi

dnf5 -y copr disable lionheartp/Hyprland

if ! rpm -q nerd-fonts >/dev/null 2>&1; then
  dnf5 -y copr enable che/nerd-fonts
  dnf5 -y install nerd-fonts
  dnf5 -y copr disable che/nerd-fonts
fi

# don't want syslinux-extlinux
rpm -q syslinux-extlinux && dnf5 remove -y syslinux-extlinux syslinux || true

# Flatpaks
cat /ctx/flatpak_install >> /usr/share/ublue-os/bazzite/flatpak/install

# Services
# - podman provides support for distroboxes
systemctl enable podman.socket
