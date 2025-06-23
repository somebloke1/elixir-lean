#!/bin/bash
# MicroBEAM post-build script
# Called by Buildroot after all packages are installed

set -e

# Remove unnecessary files to minimize size
echo "Cleaning up unnecessary files..."

# Remove documentation
rm -rf "${TARGET_DIR}/usr/share/doc"
rm -rf "${TARGET_DIR}/usr/share/man"
rm -rf "${TARGET_DIR}/usr/share/info"
rm -rf "${TARGET_DIR}/usr/share/locale"

# Remove unnecessary Erlang/OTP applications
OTP_LIB="${TARGET_DIR}/usr/lib/erlang/lib"
if [ -d "${OTP_LIB}" ]; then
    # Keep only essential OTP apps
    KEEP_APPS="kernel stdlib crypto ssl public_key asn1 compiler syntax_tools"
    
    for app in "${OTP_LIB}"/*; do
        app_name=$(basename "$app" | cut -d- -f1)
        if ! echo "$KEEP_APPS" | grep -qw "$app_name"; then
            echo "Removing OTP app: $app_name"
            rm -rf "$app"
        fi
    done
fi

# Strip all ELF binaries
find "${TARGET_DIR}" -type f -executable -exec file {} \; | \
    grep 'ELF.*executable' | \
    cut -d: -f1 | \
    xargs -r "${STRIP}" --strip-unneeded 2>/dev/null || true

# Remove static libraries
find "${TARGET_DIR}" -name "*.a" -delete

# Create minimal directory structure
mkdir -p "${TARGET_DIR}/dev"
mkdir -p "${TARGET_DIR}/proc"
mkdir -p "${TARGET_DIR}/sys"
mkdir -p "${TARGET_DIR}/tmp"
mkdir -p "${TARGET_DIR}/run"
mkdir -p "${TARGET_DIR}/var/log"

# Set permissions
chmod 1777 "${TARGET_DIR}/tmp"
chmod 755 "${TARGET_DIR}/run"

# Create minimal /etc files if not present
if [ ! -f "${TARGET_DIR}/etc/hostname" ]; then
    echo "microbeam" > "${TARGET_DIR}/etc/hostname"
fi

if [ ! -f "${TARGET_DIR}/etc/hosts" ]; then
    cat > "${TARGET_DIR}/etc/hosts" <<EOF
127.0.0.1   localhost
127.0.1.1   microbeam
EOF
fi

# Remove shell except for emergency access
# Keep only /bin/sh symlink for emergency
if [ -L "${TARGET_DIR}/bin/sh" ]; then
    # Keep the symlink but remove direct shell access
    chmod 700 "${TARGET_DIR}/bin/busybox"
fi

echo "Post-build cleanup complete"