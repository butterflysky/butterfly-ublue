# --- BUILD OPENH264 FROM SOURCE (F43) ---
echo "Building OpenH264 from source..."

# 1. Prepare build environment
# We need basic build tools + tools to fetch sources/specs
dnf5 install -y git rpmdevtools gcc gcc-c++ make nasm

# 2. Set up a temp build directory
BUILD_DIR=$(mktemp -d)
pushd "$BUILD_DIR"

# 3. Clone the Fedora 43 spec file
git clone -b f43 https://src.fedoraproject.org/rpms/openh264.git .

# 4. Download the source tarball defined in the spec
# (This handles the 'download from git' or upstream URL part automatically)
spectool -g -R openh264.spec

# 5. Install build dependencies
# This reads the .spec file and installs whatever libraries it needs from the repo
dnf5 builddep -y openh264.spec

# 6. Build the RPM
# We define _sourcedir and _rpmdir to current dir to keep it self-contained
rpmbuild -bb openh264.spec --define "_sourcedir $PWD" --define "_rpmdir $PWD"

# 7. Install the resulting RPMs
# This installs the libs which Firefox should now see
dnf5 install -y ./x86_64/*.rpm

# Cleanup
popd
rm -rf "$BUILD_DIR"
# ----------------------------------------

# NOW you can install Firefox
dnf5 install -y firefox
