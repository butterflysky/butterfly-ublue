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

# update kernel first
dnf5 -y install kernel-devel kernel-headers kernel-core

# 0) Figure out the kernel release present in the image
KREL="$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core)"

# 1) Toolchain needed by DKMS (lean set)
#dnf5 -y install gcc make elfutils-libelf-devel bc dkms

# 2) Install ZFS DKMS + userspace + matching kernel headers, but
#    suppress scriptlets/triggers so %post doesn't try to compile
  # Fallback: DKMS path (works on Bazzite/Kinoite; may require disabling Secure Boot)
dnf5 -y --setopt=tsflags=noscripts,notriggers install zfs-dkms zfs zfs-dracut

# 3) Work out the DKMS module version (e.g., "2.3.4")
ZFS_DKMS_VER="$(rpm -q --qf '%{VERSION}\n' zfs-dkms)"

# 4) Ensure the target modules dir exists (on ostree it's under /usr/lib/modules)
test -d "/usr/lib/modules/${KREL}" || mkdir -p "/usr/lib/modules/${KREL}"

# 5) Add/build/install DKMS for the TARGET kernel (not the host’s uname -r)
rm -f /var/lib/dkms/mok.key
rm -f /var/lib/dkms/mok.pub

base64 -d < /run/secrets/dkms_key > /run/dkms.key
base64 -d < /run/secrets/dkms_cert > /run/dkms.crt

openssl pkey -in /run/dkms.key -passin file:/run/secrets/dkms_pin -out /run/dkms_unenc.key

ln -sf /run/dkms_unenc.key /var/lib/dkms/mok.key
ln -sf /run/dkms.crt /var/lib/dkms/mok.pub

dkms add    -m zfs -v "${ZFS_DKMS_VER}" || true    # idempotent
dkms build  -m zfs -v "${ZFS_DKMS_VER}" -k "${KREL}"
dkms install -m zfs -v "${ZFS_DKMS_VER}" -k "${KREL}" --no-depmod

shred -u /run/dkms.key
shred -u /run/dkms_unenc.key
shred -u /run/dkms.crt

# 6) Pre-generate module dependency metadata for the target kernel
#    On ostree/bootc, modules live under /usr/lib/modules; tell depmod where to look.
depmod -b /usr -a "${KREL}"

# 7) Clean that stuff up
rm -rf /var/lib/dkms/* /var/lib/dkms/.??* 2>/dev/null || true

# ceph
# directories some packages expect; safe if created early
mkdir -p /var/lib/ceph /var/log/ceph

# ensure ceph service account exists for ceph-common %scripts
useradd -r -c "Ceph storage service" -d /var/lib/ceph -M  -s /sbin/nologin ceph
chown ceph:ceph /var/lib/ceph /var/log/ceph

dnf5 install -y \
  ceph-common ceph-fuse

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
  cfonts \
  cosign \
  direnv \
  evtest \
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

if ! rpm -q nerd-fonts >/dev/null 2>&1; then
  dnf5 -y copr enable che/nerd-fonts
  dnf5 -y install nerd-fonts
  dnf5 -y copr disable che/nerd-fonts
fi

rpm -q syslinux-extlinux && dnf5 remove -y syslinux-extlinux syslinux || true

# Flatpaks
cat /ctx/flatpak_install >> /usr/share/ublue-os/bazzite/flatpak/install

# Extras (your scripts)
/ctx/install-1password.sh
/ctx/install-chrome.sh

# Services
systemctl enable podman.socket

set +x
# snapshot after installs
AFTER_PW=$(mktemp) ; AFTER_GR=$(mktemp)
sh -c "getent passwd" | sort > "$AFTER_PW"
sh -c "getent group"  | sort > "$AFTER_GR"

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
  if [[ "$uid" -lt 1000 || "$shell" == "/sbin/nologin" || "$shell" == "/bin/false" ]]; then
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
set -x

# make result readable in the image
chmod 0644 "$SYSUSERS_OUT"

cat "$SYSUSERS_OUT"

# Create tmpfiles rules
cat >/usr/lib/tmpfiles.d/99-local-packages.conf <<EOF
# Ceph
d /var/lib/ceph 0750 ceph ceph - -
d /var/log/ceph 0755 ceph ceph - -

# DKMS + ZFS (adjust version if it changes)
d /var/lib/dkms 0755 root root - -
d /var/lib/dkms/zfs 0755 root root - -
d /var/lib/dkms/zfs/${ZFS_DKMS_VER} 0755 root root - -
L /var/lib/dkms/zfs/${ZFS_DKMS_VER}/source - - - - /usr/src/zfs-${ZFS_DKMS_VER}

# dhcpcd (present in base)
d /var/lib/dhcpcd 0755 root dhcpcd - -

d /var/lib/dkms/zfs/${ZFS_DKMS_VER}/build 0755 root root - -
d /var/lib/pcp 0755 root root - -
d /var/lib/pcp/config 0755 root root - -
d /var/lib/pcp/config/derived 0755 root root - -
d /var/lib/rpm-state 0755 root root - -
EOF

ls -lR /boot
# cleanup
rm -f "$BEFORE_PW" "$BEFORE_GR" "$AFTER_PW" "$AFTER_GR"

rm -fr ctx/certs
