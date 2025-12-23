set -ouex pipefail

# --- BUILD OPENH264 FROM SOURCE (F43) ---
echo "Building OpenH264 from source..."

# 1. Install build dependencies
dnf5 install -y git rpmdevtools gcc gcc-c++ make nasm

# 2. Setup the RPM build tree manually
# Standard tools expect this structure at %{_topdir} (defaults to ~/rpmbuild)
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# 3. Clone the Fedora 43 spec file
# We clone into a temp folder, then move the spec to the standard location
TEMP_CLONE=$(mktemp -d)
git clone -b f43 https://src.fedoraproject.org/rpms/openh264.git "$TEMP_CLONE"
cp "$TEMP_CLONE/openh264.spec" ~/rpmbuild/SPECS/
rm -rf "$TEMP_CLONE"

# 4. Download sources
# -g: Get sources
# -C: Download target directory (Must be the SOURCES dir we just created)
spectool -g -R ~/rpmbuild/SPECS/openh264.spec -C ~/rpmbuild/SOURCES/

# 5. Install build dependencies
# This reads the spec and installs libraries needed for compilation
dnf5 builddep -y ~/rpmbuild/SPECS/openh264.spec

# 6. Build the RPM
# We don't need fancy defines now because we are using the standard ~/rpmbuild structure
rpmbuild -bb ~/rpmbuild/SPECS/openh264.spec

# 7. Install the resulting RPMs
dnf5 install -y ~/rpmbuild/RPMS/x86_64/*.rpm

# Cleanup the build tree to save space in the final image
rm -rf ~/rpmbuild
#
# ----------------------------------------
# NOW you can install Firefox
dnf5 install -y firefox
