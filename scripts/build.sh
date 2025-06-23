#!/bin/bash
# MicroBEAM build script
# Builds the entire MicroBEAM system using Buildroot

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILDROOT_DIR="${PROJECT_ROOT}/buildroot"
BR_VERSION="2023.11"
BR_DL_DIR="${HOME}/buildroot-dl"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[MicroBEAM]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Check dependencies
check_deps() {
    log "Checking build dependencies..."
    
    local deps=("git" "make" "gcc" "g++" "patch" "cpio" "unzip" "rsync" "bc" "wget")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing dependencies: ${missing[*]}\nInstall with: sudo apt-get install ${missing[*]}"
    fi
}

# Download Buildroot if needed
download_buildroot() {
    if [ ! -d "${BUILDROOT_DIR}/buildroot-${BR_VERSION}" ]; then
        log "Downloading Buildroot ${BR_VERSION}..."
        mkdir -p "${BUILDROOT_DIR}"
        cd "${BUILDROOT_DIR}"
        wget -q "https://buildroot.org/downloads/buildroot-${BR_VERSION}.tar.gz"
        tar xzf "buildroot-${BR_VERSION}.tar.gz"
        rm "buildroot-${BR_VERSION}.tar.gz"
    fi
}

# Prepare build directory
prepare_build() {
    log "Preparing build directory..."
    
    BR_BUILD_DIR="${BUILDROOT_DIR}/build"
    mkdir -p "${BR_BUILD_DIR}"
    
    # Create symlink to configs
    ln -sfn "${BUILDROOT_DIR}/configs" "${BR_BUILD_DIR}/configs"
    
    # Set download directory
    mkdir -p "${BR_DL_DIR}"
}

# Build Elixir application
build_elixir_app() {
    log "Building Elixir application..."
    
    cd "${PROJECT_ROOT}/elixir-app"
    
    # Fetch dependencies
    MIX_ENV=prod mix deps.get --only prod
    
    # Compile
    MIX_ENV=prod mix compile
    
    # Create release
    MIX_ENV=prod mix release --overwrite
    
    # Copy release to staging area
    RELEASE_DIR="${PROJECT_ROOT}/buildroot/rootfs_overlay/app"
    rm -rf "${RELEASE_DIR}"
    mkdir -p "${RELEASE_DIR}"
    cp -r "_build/prod/rel/microbeam/"* "${RELEASE_DIR}/"
}

# Configure Buildroot
configure_buildroot() {
    log "Configuring Buildroot..."
    
    cd "${BR_BUILD_DIR}"
    
    make -C "${BUILDROOT_DIR}/buildroot-${BR_VERSION}" \
        O="${BR_BUILD_DIR}" \
        BR2_EXTERNAL="${BUILDROOT_DIR}" \
        BR2_DL_DIR="${BR_DL_DIR}" \
        microbeam_defconfig
}

# Build system
build_system() {
    log "Building MicroBEAM system (this may take a while)..."
    
    cd "${BR_BUILD_DIR}"
    
    # Use all available cores
    JOBS=$(nproc)
    
    make -j${JOBS} 2>&1 | tee build.log
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        error "Build failed! Check ${BR_BUILD_DIR}/build.log for details"
    fi
}

# Create final image
create_image() {
    log "Creating final MicroBEAM image..."
    
    IMAGE_DIR="${PROJECT_ROOT}/images"
    mkdir -p "${IMAGE_DIR}"
    
    # Copy kernel and rootfs
    cp "${BR_BUILD_DIR}/images/bzImage" "${IMAGE_DIR}/microbeam-kernel"
    cp "${BR_BUILD_DIR}/images/rootfs.cpio.xz" "${IMAGE_DIR}/microbeam-rootfs.cpio.xz"
    
    # Calculate sizes
    KERNEL_SIZE=$(du -h "${IMAGE_DIR}/microbeam-kernel" | cut -f1)
    ROOTFS_SIZE=$(du -h "${IMAGE_DIR}/microbeam-rootfs.cpio.xz" | cut -f1)
    TOTAL_SIZE=$(du -ch "${IMAGE_DIR}/"* | grep total | cut -f1)
    
    log "Build complete!"
    echo -e "${GREEN}========================================${NC}"
    echo -e "Kernel size: ${YELLOW}${KERNEL_SIZE}${NC}"
    echo -e "RootFS size: ${YELLOW}${ROOTFS_SIZE}${NC}"
    echo -e "Total size:  ${YELLOW}${TOTAL_SIZE}${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo "Images created in: ${IMAGE_DIR}/"
    echo "Run with: ${SCRIPT_DIR}/run-qemu.sh"
}

# Main build process
main() {
    log "Starting MicroBEAM build process..."
    
    check_deps
    download_buildroot
    prepare_build
    build_elixir_app
    configure_buildroot
    build_system
    create_image
    
    log "Build completed successfully!"
}

# Run main
main "$@"