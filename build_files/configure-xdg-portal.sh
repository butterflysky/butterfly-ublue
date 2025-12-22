# xdg-portal-configs

echo "Configuring XDG Portals..."
mkdir -p /etc/xdg-desktop-portal
cat >/etc/xdg-desktop-portal/portals.conf <<EOF
[Hyprland]
default=hyprland;gtk
org.freedesktop.impl.portal.Secret=gnome-keyring

[KDE]
default=kde
EOF

# PREVENT GNOME KEYRING FROM STARTING IN KDE
# We add "NotShowIn=KDE;" to the gnome-keyring autostart files.
# This ensures it only runs when we explicitly ask for it (Hyprland)
# or in GTK environments, but keeps your Plasma session pure.

echo "Patching Gnome Keyring autostart..."
find /usr/etc/xdg/autostart -name "gnome-keyring*.desktop" -exec \
    sed -i '/^OnlyShowIn=/d; $a NotShowIn=KDE;' {} +

# Note: In uBlue/Silverblue, /etc/xdg might be a symlink or empty,
# and the actual files are often in /usr/etc/xdg or /usr/share/applications.
# We try /usr/etc/xdg/autostart first as that is the OSTree standard location.
# If your distro puts them in /usr/share, duplicate the line for that path:
find /usr/share/applications -name "gnome-keyring*.desktop" -exec \
    sed -i '/^OnlyShowIn=/d; $a NotShowIn=KDE;' {} +
