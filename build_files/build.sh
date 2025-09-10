#!/bin/bash

set -ouex pipefail

# snapshot users/groups before installs
BEFORE_PW=$(mktemp) ; BEFORE_GR=$(mktemp)
getent passwd | sort > "$BEFORE_PW"
getent group  | sort > "$BEFORE_GR"

### Install packages

### Repos / prelim
# Remove wrong ZFS if present (you don't want zfs-fuse on this image)
rpm -q zfs-fuse && dnf5 remove -y zfs-fuse || true

# OpenZFS repo (required for akmod-zfs/zfs/zfs-dracut)
rpm -q zfs-release || dnf5 install -y "https://github.com/zfsonlinux/zfsonlinux.github.com/raw/refs/heads/master/fedora/zfs-release-2-8.fc42.noarch.rpm"

# Prefer prebuilt kernel modules if available
if dnf5 list --available kmod-zfs >/dev/null 2>&1; then
  dnf5 install -y zfs zfs-dracut kmod-zfs
else
  # Fallback: DKMS path (works on Bazzite/Kinoite; may require disabling Secure Boot)
  dnf5 install -y zfs zfs-dracut zfs-dkms linux-devel
fi

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

dnf5 install -y \
  age \
  ansible ansible-lint \
  bcachefs-tools \
  bpftool bpftrace \
  btrbk \
  buildah \
  ceph-common ceph-fuse \
  cfonts \
  clevis clevis-dracut clevis-luks \
  cosign \
  direnv \
  evtest \
  fd \
  fd-find \
  firefox \
  foot \
  fzf \
  grim \
  helm \
  hyprland \
  xdg-desktop-portal-hyprland xorg-x11-server-Xwayland qt5-qtwayland qt6-qtwayland \
  iproute-tc iptables-nft nftables \
  jq yq \
  k9s \
  kubectl \
  kustomize \
  libguestfs-tools \
  netcat nmap \
  perf \
  podman-remote \
  restic \
  ripgrep \
  slurp \
  strace \
  swappy \
  tilt \
  virt-install virt-manager virt-viewer \
  waybar wl-clipboard wofi \
  zoxide \
  zsh zsh-syntax-highlighting


# Temporary COPR: Nerd Fonts (enable → install → disable)
dnf5 -y copr enable che/nerd-fonts
dnf5 -y install nerd-fonts
dnf5 -y copr disable che/nerd-fonts

# Flatpaks
cat /ctx/flatpak_install >> /usr/share/ublue-os/bazzite/flatpak/install

# Extras (your scripts)
/ctx/install-1password.sh
/ctx/install-chrome.sh

# Services
systemctl enable podman.socket

# snapshot after installs
AFTER_PW=$(mktemp) ; AFTER_GR=$(mktemp)
getent passwd | sort > "$AFTER_PW"
getent group  | sort > "$AFTER_GR"

# output file baked into the image
SYSUSERS_OUT="/usr/lib/sysusers.d/99-local-packages.conf"
mkdir -p "$(dirname "$SYSUSERS_OUT")"
: > "$SYSUSERS_OUT"

# helper: map gid -> group name from AFTER snapshot
# (assumes unique gid→name mapping)
declare -A GID2NAME
while IFS=: read -r gname _ gid _; do
  GID2NAME["$gid"]="$gname"
done < "$AFTER_GR"

# build sets of "before" users/groups for quick membership checks
declare -A BEFORE_USERS BEFORE_GROUPS
while IFS=: read -r uname _ _ _ _ _ _; do BEFORE_USERS["$uname"]=1; done < "$BEFORE_PW"
while IFS=: read -r gname _ _ _; do BEFORE_GROUPS["$gname"]=1; done < "$BEFORE_GR"

# emit sysusers for *new* groups (system-ish only: gid < 1000)
while IFS=: read -r gname _ gid _; do
  [[ -n "${BEFORE_GROUPS[$gname]:-}" ]] && continue
  # only capture system groups; adjust threshold if your site policy differs
  if [[ "$gid" -lt 1000 ]]; then
    printf 'g %s %s\n' "$gname" "$gid" >> "$SYSUSERS_OUT"
  fi
done < "$AFTER_GR"

# emit sysusers for *new* users (system-ish only: uid < 1000 OR nologin/false shells)
while IFS=: read -r uname x uid gid gecos home shell; do
  [[ -n "${BEFORE_USERS[$uname]:-}" ]] && continue

  # heuristics for service accounts
  if [[ "$uid" -lt 1000 || "$shell" =~ (nologin|false)$ ]]; then
    # ensure primary group exists in sysusers (by name) if it was added
    gname="${GID2NAME[$gid]}"
    # user line: u name uid:group "GECOS" home shell
    # quote GECOS if present; fall back to "-" to be minimal
    [[ -z "$gecos" ]] && gecos="-" || gecos="\"$gecos\""
    [[ -z "$home"  ]] && home="-"
    [[ -z "$shell" ]] && shell="-"
    if [[ -n "$gname" ]]; then
      printf 'u %s %s:%s %s %s %s\n' "$uname" "$uid" "$gname" "$gecos" "$home" "$shell" >> "$SYSUSERS_OUT"
    else
      # if we couldn't map gid→name, just pin numeric gid by using a pre-created group
      printf 'u %s %s %s %s %s\n' "$uname" "$uid" "$gecos" "$home" "$shell" >> "$SYSUSERS_OUT"
    fi
  fi
done < "$AFTER_PW"

# make result readable in the image
chmod 0644 "$SYSUSERS_OUT"

# cleanup
rm -f "$BEFORE_PW" "$BEFORE_GR" "$AFTER_PW" "$AFTER_GR"
