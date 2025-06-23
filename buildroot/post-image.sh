#!/bin/bash
# MicroBEAM post-image script
# Called after filesystem image is created

set -e

BOARD_DIR="$(dirname $0)"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# Report final image sizes
echo "=== MicroBEAM Image Statistics ==="
echo "Kernel size: $(du -h ${BINARIES_DIR}/bzImage | cut -f1)"
echo "RootFS size: $(du -h ${BINARIES_DIR}/rootfs.cpio.xz | cut -f1)"

# Calculate uncompressed size
if [ -f "${BINARIES_DIR}/rootfs.cpio" ]; then
    echo "RootFS uncompressed: $(du -h ${BINARIES_DIR}/rootfs.cpio | cut -f1)"
fi

# List largest directories in rootfs
echo
echo "=== Largest directories in rootfs ==="
if [ -d "${TARGET_DIR}" ]; then
    du -sh ${TARGET_DIR}/* 2>/dev/null | sort -hr | head -10
fi

echo
echo "=== OTP applications included ==="
if [ -d "${TARGET_DIR}/usr/lib/erlang/lib" ]; then
    ls -1 ${TARGET_DIR}/usr/lib/erlang/lib/
fi

echo
echo "Build complete! Total image size: $(du -ch ${BINARIES_DIR}/bzImage ${BINARIES_DIR}/rootfs.cpio.xz | grep total | cut -f1)"