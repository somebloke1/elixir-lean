#!/bin/bash
# Run MicroBEAM in QEMU

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_DIR="${PROJECT_ROOT}/images"

# Default settings
MEMORY="256M"
CPUS="2"
PORT="4000"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -m MEMORY    Memory size (default: ${MEMORY})"
    echo "  -c CPUS      Number of CPUs (default: ${CPUS})"
    echo "  -p PORT      Forward host port to VM port 4000 (default: ${PORT})"
    echo "  -d           Enable debug output"
    echo "  -h           Show this help"
    exit 1
}

# Parse arguments
DEBUG=""
while getopts "m:c:p:dh" opt; do
    case $opt in
        m) MEMORY="$OPTARG" ;;
        c) CPUS="$OPTARG" ;;
        p) PORT="$OPTARG" ;;
        d) DEBUG="1" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check for required files
if [ ! -f "${IMAGE_DIR}/microbeam-kernel" ]; then
    echo "Error: Kernel not found. Run build.sh first."
    exit 1
fi

if [ ! -f "${IMAGE_DIR}/microbeam-rootfs.cpio.xz" ]; then
    echo "Error: Root filesystem not found. Run build.sh first."
    exit 1
fi

echo -e "${GREEN}Starting MicroBEAM VM...${NC}"
echo -e "Memory: ${YELLOW}${MEMORY}${NC}"
echo -e "CPUs:   ${YELLOW}${CPUS}${NC}"
echo -e "Port:   ${YELLOW}localhost:${PORT} -> VM:4000${NC}"
echo
echo "Press Ctrl-A X to exit QEMU"
echo

# Build QEMU command
QEMU_CMD=(
    qemu-system-x86_64
    -M q35
    -cpu host
    -enable-kvm
    -m "${MEMORY}"
    -smp "${CPUS}"
    -kernel "${IMAGE_DIR}/microbeam-kernel"
    -initrd "${IMAGE_DIR}/microbeam-rootfs.cpio.xz"
    -append "console=ttyS0 quiet"
    -nographic
    -serial mon:stdio
    -netdev user,id=net0,hostfwd=tcp::${PORT}-:4000
    -device virtio-net-pci,netdev=net0
    -device virtio-rng-pci
)

# Add debug options if requested
if [ -n "$DEBUG" ]; then
    QEMU_CMD+=(-d cpu_reset,int,guest_errors)
fi

# Run QEMU
exec "${QEMU_CMD[@]}"