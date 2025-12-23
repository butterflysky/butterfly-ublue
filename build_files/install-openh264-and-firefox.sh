set -ouex pipefail

# --- BUILD OPENH264 FROM SOURCE (F43) ---
echo "Building OpenH264 from source..."

# 1. Install build dependencies
dnf5 install -y git rpmdevtools gcc gcc-c++ make nasm

# 2. Setup the RPM build tree in /var/tmp
RPM_ROOT="/var/tmp/rpmbuild"
mkdir -p "$RPM_ROOT"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# 3. Clone the Fedora 43 repo
TEMP_CLONE=$(mktemp -d)
git clone -b f43 https://src.fedoraproject.org/rpms/openh264.git "$TEMP_CLONE"

# 4. Move files to correct locations
# Spec goes to SPECS
cp "$TEMP_CLONE/openh264.spec" "$RPM_ROOT/SPECS/"
# Patches (and other local files) must go to SOURCES
cp "$TEMP_CLONE/"*.patch "$RPM_ROOT/SOURCES/" 2>/dev/null || true

rm -rf "$TEMP_CLONE"

# 5. Download remote source tarballs
# (Downloads the big .tar.gz files into SOURCES)
spectool -g -C "$RPM_ROOT/SOURCES/" "$RPM_ROOT/SPECS/openh264.spec"

# 6. Install build deps
dnf5 builddep -y "$RPM_ROOT/SPECS/openh264.spec"

# 7. Build the RPM
rpmbuild -bb "$RPM_ROOT/SPECS/openh264.spec" --define "_topdir $RPM_ROOT"

# 8. Install the result
dnf5 install -y "$RPM_ROOT/RPMS/x86_64/"*.rpm

# Cleanup
rm -rf "$RPM_ROOT"
# ----------------------------------------
dnf5 install -y firefox
