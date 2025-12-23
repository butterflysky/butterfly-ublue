set -ouex pipefail

# --- BUILD OPENH264 FROM SOURCE (F43) ---
echo "Building OpenH264 from source..."

# 1. Install build dependencies
dnf5 install -y git rpmdevtools gcc gcc-c++ make nasm

# 2. Setup the RPM build tree in /var/tmp (Safe from OSTree symlink weirdness)
# We avoid ~/rpmbuild because /root is a symlink and mkdir -p hates it.
RPM_ROOT="/var/tmp/rpmbuild"
mkdir -p "$RPM_ROOT"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# 3. Clone the Fedora 43 spec file
TEMP_CLONE=$(mktemp -d)
git clone -b f43 https://src.fedoraproject.org/rpms/openh264.git "$TEMP_CLONE"
cp "$TEMP_CLONE/openh264.spec" "$RPM_ROOT/SPECS/"
rm -rf "$TEMP_CLONE"

# 4. Download sources
# Point spectool to our custom /var/tmp directories
spectool -g -R "$RPM_ROOT/SPECS/openh264.spec" -C "$RPM_ROOT/SOURCES/"

# 5. Install build dependencies
dnf5 builddep -y "$RPM_ROOT/SPECS/openh264.spec"

# 6. Build the RPM
# Explicitly define the topdir to our safe location
rpmbuild -bb "$RPM_ROOT/SPECS/openh264.spec" --define "_topdir $RPM_ROOT"

# 7. Install the resulting RPMs
dnf5 install -y "$RPM_ROOT/RPMS/x86_64/"*.rpm

# Cleanup
rm -rf "$RPM_ROOT"
# ----------------------------------------
dnf5 install -y firefox
