#!/bin/bash

set -ouex pipefail

# ceph
# directories some packages expect; safe if created early
mkdir -p /var/lib/ceph /var/log/ceph

# ensure ceph service account exists for ceph-common %scripts
useradd -r -c "Ceph storage service" -d /var/lib/ceph -M  -s /sbin/nologin ceph
chown ceph:ceph /var/lib/ceph /var/log/ceph

dnf5 install -y \
  ceph-common ceph-fuse

# Create tmpfiles rules
cat >/usr/lib/tmpfiles.d/97-local-ceph.conf <<EOF
# Ceph
d /var/lib/ceph 0750 ceph ceph - -
d /var/log/ceph 0755 ceph ceph - -
EOF
