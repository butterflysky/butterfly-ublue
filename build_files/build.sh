#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y \
  age \
  akmod-zfs \
  ansible \
  ansible-lint \
  bcachefs-tools \
  bpftool \
  bpftrace \
  btrbk \
  buildah \
  ceph-common \
  ceph-fuse \
  cfonts \
  cilium-cli \
  clevis \
  clevis-dracut \
  clevis-luks \
  cosign \
  direnv \
  dive \
  evtest \
  fd \
  fd-find \
  firefox \
  fluxcd \
  foot \
  fzf \
  grim \
  helm \
  hyprland \
  hyprland-plugins \
  iproute-tc \
  iptables-nft \
  jq \
  k9s \
  krew \
  kubectl \
  kubectx \
  kubens \
  kubeseal \
  kubetail \
  kustomize \
  libguestfs-tools \
  netcat \
  nftables \
  nmap \
  pam_ssh_agent_auth \
  perf \
  podman-remote \
  radowsgw-agent \
  restic \
  ripgrep \
  skaffold \
  slurp \
  sops \
  stern \
  strace \
  swappy \
  syncthing \
  tilt \
  virt-install \
  virt-manager \
  virt-viewer \
  waybar \
  wl-clipboard \
  wofi \
  yq \
  ytt \
  zfs \
  zfs-dracut \
  zoxide \
  zsh \
  zsh-syntax-highlighting

dnf5 -y copr enable che/nerd-fonts
dnf5 -y install cfonts nerd-fonts
dnf5 -y copr disable che/nerd-fonts

cat /ctx/flatpak_install >> /usr/share/ublue-os/bazzite/flatpak/install

/ctx/install-1password.sh
/ctx/install-chrome.sh

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

systemctl enable podman.socket
