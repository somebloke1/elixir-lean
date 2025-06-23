# MicroBEAM Quick Start Guide

## Prerequisites

- Linux host system (Ubuntu 20.04+ or similar)
- 10GB free disk space
- 4GB+ RAM
- QEMU with KVM support
- Development tools:
  ```bash
  sudo apt-get install build-essential git wget cpio bc \
                       qemu-system-x86-64 elixir erlang-dev \
                       libssl-dev libncurses5-dev
  ```

## Building MicroBEAM

1. **Clone the repository**
   ```bash
   git clone https://github.com/elixir-lean/elixir-lean
   cd elixir-lean
   ```

2. **Run the build script**
   ```bash
   ./scripts/build.sh
   ```
   
   This will:
   - Download Buildroot
   - Build the minimal kernel
   - Compile the Elixir application
   - Create the root filesystem
   - Generate VM images

   First build takes 30-60 minutes. Subsequent builds are faster.

3. **Check the output**
   ```bash
   ls -lh images/
   # microbeam-kernel     (2-3MB)
   # microbeam-rootfs.cpio.xz (13-15MB)
   ```

## Running in QEMU

1. **Start the VM**
   ```bash
   ./scripts/run-qemu.sh
   ```

2. **Access the application**
   ```bash
   # In another terminal:
   curl http://localhost:4000/
   curl http://localhost:4000/health
   ```

3. **Stop the VM**
   - Press `Ctrl-A` then `X` in the QEMU console

## Customization Options

### Change Memory/CPU
```bash
./scripts/run-qemu.sh -m 512M -c 4
```

### Different Port Mapping
```bash
./scripts/run-qemu.sh -p 8080  # Maps localhost:8080 to VM:4000
```

### Debug Mode
```bash
./scripts/run-qemu.sh -d  # Enables QEMU debug output
```

## Modifying the Elixir Application

1. **Edit the application**
   ```bash
   cd elixir-app/
   # Make your changes to lib/microbeam/
   ```

2. **Test locally**
   ```bash
   mix test
   mix run --no-halt
   ```

3. **Rebuild the image**
   ```bash
   cd ..
   ./scripts/build.sh
   ```

## Emergency Shell Access

If needed, you can access the emergency shell:

1. **During boot issues**: The system will fall back to `/bin/sh` if BEAM fails
2. **Manual access**: Modify `beam-init.c` to start shell instead of BEAM

## Troubleshooting

### Build Fails
- Check you have all prerequisites installed
- Ensure 10GB free disk space
- Review `buildroot/build/build.log`

### VM Won't Boot
- Verify KVM is enabled: `kvm-ok`
- Check kernel output by removing `quiet` from run-qemu.sh
- Try without KVM: Remove `-enable-kvm` from run-qemu.sh

### Application Not Responding
- Check BEAM started: Look for startup messages
- Verify network: The VM should show network initialization
- Check application logs in QEMU console

### Out of Memory
- Increase memory: `./scripts/run-qemu.sh -m 512M`
- Check for memory leaks in your Elixir code
- Monitor with included system endpoints

## Advanced Usage

### Custom Kernel Config
1. Edit `kernel/microbeam.config`
2. Rebuild: `./scripts/build.sh`

### Additional OTP Applications
1. Modify `buildroot/post-build.sh` KEEP_APPS list
2. Update Buildroot Erlang package config
3. Rebuild

### Production Deployment
1. Build release image
2. Convert to your hypervisor format:
   ```bash
   qemu-img convert -f raw -O vmdk images/microbeam.img microbeam.vmdk
   ```
3. Import to VMware, VirtualBox, or cloud provider

## Performance Tuning

- **CPU**: Use `-cpu host` for best performance
- **Memory**: Start with 256MB, adjust based on load
- **Network**: VirtIO provides near-native speed
- **Storage**: Use tmpfs for temporary data

## Security Hardening

For production use:
1. Change the RELEASE_COOKIE in beam-init.c
2. Implement proper firewall rules on the host
3. Use read-only root filesystem
4. Run VMs in isolated network segments

## Getting Help

- GitHub Issues: https://github.com/elixir-lean/elixir-lean/issues
- Documentation: See ARCHITECTURE.md for detailed information
- Elixir Forum: https://elixirforum.com/