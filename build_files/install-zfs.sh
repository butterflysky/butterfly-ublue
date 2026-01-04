#!/bin/bash

set -ouex pipefail

### Repos / prelim
# stripping ZFS support for now
## # Remove wrong ZFS if present (you don't want zfs-fuse on this image)
## rpm -q zfs-fuse && dnf5 remove -y zfs-fuse || true

## # OpenZFS repo (required for akmod-zfs/zfs/zfs-dracut)
## rpm -q zfs-release || dnf5 install -y "https://github.com/zfsonlinux/zfsonlinux.github.com/raw/refs/heads/master/fedora/zfs-release-3-0.fc43.noarch.rpm"

# update kernel first
## dnf5 -y install kernel-devel kernel-headers kernel-core

# 0) Figure out the kernel release present in the image
## KREL="$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core)"

## # 1) Toolchain needed by DKMS (lean set)
## #dnf5 -y install gcc make elfutils-libelf-devel bc dkms

## # 2) Install ZFS DKMS + userspace + matching kernel headers, but
## #    suppress scriptlets/triggers so %post doesn't try to compile
  # Fallback: DKMS path (works on Bazzite/Kinoite; may require disabling Secure Boot)
## dnf5 -y --setopt=tsflags=noscripts,notriggers install zfs-dkms zfs zfs-dracut

## # 3) Work out the DKMS module version (e.g., "2.3.4")
## ZFS_DKMS_VER="$(rpm -q --qf '%{VERSION}\n' zfs-dkms)"

## # 4) Ensure the target modules dir exists (on ostree it's under /usr/lib/modules)
## test -d "/usr/lib/modules/${KREL}" || mkdir -p "/usr/lib/modules/${KREL}"

# 5) Add/build/install DKMS for the TARGET kernel (not the host’s uname -r)
## rm -f /var/lib/dkms/mok.key
## rm -f /var/lib/dkms/mok.pub

## base64 -d < /run/secrets/dkms_key > /run/dkms.key
## base64 -d < /run/secrets/dkms_cert > /run/dkms.crt

## openssl pkey -in /run/dkms.key -passin file:/run/secrets/dkms_pin -out /run/dkms_unenc.key

## ln -sf /run/dkms_unenc.key /var/lib/dkms/mok.key
## ln -sf /run/dkms.crt /var/lib/dkms/mok.pub

## dkms add    -m zfs -v "${ZFS_DKMS_VER}" || true    # idempotent
## dkms build  -m zfs -v "${ZFS_DKMS_VER}" -k "${KREL}"
## dkms install -m zfs -v "${ZFS_DKMS_VER}" -k "${KREL}" --no-depmod

## shred -u /run/dkms.key
## shred -u /run/dkms_unenc.key
## shred -u /run/dkms.crt

# 6) Pre-generate module dependency metadata for the target kernel
#    On ostree/bootc, modules live under /usr/lib/modules; tell depmod where to look.
## depmod -b /usr -a "${KREL}"

# 7) Clean that stuff up
## rm -rf /var/lib/dkms/* /var/lib/dkms/.??* 2>/dev/null || true

# Create tmpfiles rules
## cat >/usr/lib/tmpfiles.d/98-local-zfs.conf <<EOF
## # DKMS + ZFS (adjust version if it changes)
## d /var/lib/dkms 0755 root root - -
## d /var/lib/dkms/zfs 0755 root root - -
## d /var/lib/dkms/zfs/${ZFS_DKMS_VER} 0755 root root - -
## L /var/lib/dkms/zfs/${ZFS_DKMS_VER}/source - - - - /usr/src/zfs-${ZFS_DKMS_VER}
## d /var/lib/dkms/zfs/${ZFS_DKMS_VER}/build 0755 root root - -
## EOF

## rm -fr ctx/certs
