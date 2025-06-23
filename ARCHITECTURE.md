# MicroBEAM Architecture Documentation

## Overview

MicroBEAM represents an experimental ultra-minimal Linux VM architecture where the BEAM (Erlang VM) runs directly as PID 1, eliminating traditional init systems. This approach achieves a total system size of 15-18MB while maintaining full Elixir execution capability.

## Design Philosophy

### Core Principles

1. **BEAM-First Design**: The BEAM VM is the primary supervisor, not a secondary process
2. **Ruthless Minimization**: Every byte counts - no unnecessary components
3. **VM-Optimized**: Leverages paravirtualization for efficiency
4. **Single Purpose**: Optimized for running one Elixir application

### Trade-offs

- **No Shell Access**: BusyBox is present but restricted (chmod 700)
- **Limited Debugging**: Minimal logging and diagnostics
- **Fixed Configuration**: Most settings are compile-time decisions
- **No Package Management**: All software is baked into the image

## Component Breakdown

### Linux Kernel (2-3MB)

Starting from `tinyconfig`, the kernel includes only:
- Essential VM drivers (VirtIO for network, block, console)
- Memory management for BEAM (MMU, SYSVIPC)
- Process management (fork, futex, epoll)
- Minimal filesystems (ext4, tmpfs, proc, sys)
- Network stack (TCP/IP, Unix sockets)

Key optimizations:
- XZ compression (60-70% size reduction)
- No modules - everything built-in
- No USB, sound, wireless support
- Disabled power management
- Minimal crypto (only for BEAM SSL)

### beam-init (10-50KB)

A tiny C program that:
1. Mounts essential filesystems (/proc, /sys, /dev)
2. Sets minimal environment variables
3. Execs the BEAM VM to replace itself

This eliminates the need for traditional init systems like systemd or BusyBox init.

### Root Filesystem Structure

```
/
├── app/                    # Elixir release
│   ├── bin/               # Release scripts
│   ├── lib/               # BEAM files
│   └── releases/          # Release metadata
├── bin/                   # Minimal BusyBox utilities
├── dev/                   # Device nodes (devtmpfs)
├── etc/                   # Minimal config files
│   ├── hostname
│   ├── hosts
│   └── os-release
├── lib/                   # musl libc and dependencies
├── proc/                  # Process information (procfs)
├── run/                   # Runtime state (tmpfs)
├── sbin/                  # System binaries
│   └── beam-init          # Our custom init
├── sys/                   # System information (sysfs)
├── tmp/                   # Temporary files (tmpfs)
├── usr/
│   └── lib/
│       ├── erlang/        # BEAM runtime
│       └── elixir/        # Elixir libraries
└── var/
    └── log/               # Logs (if any)
```

### BEAM Runtime (8-10MB)

Stripped Erlang/OTP with only essential applications:
- `kernel`: Core Erlang functionality
- `stdlib`: Standard library
- `crypto`: Cryptographic functions
- `ssl`: TLS support
- `public_key`, `asn1`: SSL dependencies

Removed OTP applications save 10MB+:
- No GUI tools (observer, debugger)
- No database (mnesia)
- No distributed tools (reltool, common_test)
- No legacy protocols (ftp, tftp)

### Elixir Application (3-4MB)

Mix release with:
- Stripped BEAM files
- No source code
- Compressed assets
- Minimal dependencies

## Boot Process

1. **Kernel Boot** (0-50ms)
   - Loads compressed kernel into memory
   - Initializes minimal hardware (VirtIO)
   - Mounts initramfs as root

2. **beam-init Execution** (50-100ms)
   - Kernel executes /init (symlink to beam-init)
   - Mounts virtual filesystems
   - Sets up environment

3. **BEAM Startup** (100-200ms)
   - beam-init execs BEAM VM
   - BEAM becomes PID 1
   - Loads precompiled modules

4. **Application Start** (150-250ms)
   - OTP application supervisor starts
   - Elixir application initializes
   - HTTP server begins accepting connections

Total boot time: ~200ms to serving HTTP requests

## Memory Layout

Typical runtime memory usage:
- Kernel: 10-15MB
- BEAM VM: 20-30MB
- Application: 5-10MB
- Buffers/Cache: 10-15MB

Total: ~50MB for a running system

## Networking

- VirtIO network device for performance
- Single network interface (eth0)
- DHCP client not included (static IP or container networking)
- iptables/netfilter disabled in kernel

## Security Considerations

### Strengths
- Minimal attack surface
- No shell access in production
- Read-only root filesystem possible
- No package manager = no supply chain attacks

### Weaknesses
- Limited security updates
- No SELinux/AppArmor
- Minimal user separation (everything runs as root)
- No firewall by default

## Performance Characteristics

- **Boot Time**: <200ms cold boot
- **Memory**: 50MB runtime footprint
- **CPU**: Near-native performance with KVM
- **Network**: Line-rate with VirtIO
- **Disk I/O**: Minimal (mostly RAM-based)

## Development Workflow

1. **Local Development**: Standard Elixir/Mix workflow
2. **Testing**: Run tests before building image
3. **Building**: ~5-10 minute build with Buildroot
4. **Deployment**: Copy 15-18MB image to hosts

## Monitoring and Debugging

Limited to:
- Application logs (via Logger)
- HTTP health endpoints
- BEAM crash dumps (redirected to /dev/null)
- Emergency shell access (if needed)

## Use Cases

Ideal for:
- High-density VM hosting (200+ VMs per host)
- Immutable infrastructure
- Edge computing with constraints
- CI/CD test environments
- Learning/experimentation

Not suitable for:
- General-purpose servers
- Development environments
- Systems requiring regular updates
- Multi-tenant applications

## Future Optimizations

Potential improvements:
- Custom BEAM build with fewer instructions
- Kernel compression with ZSTD
- Dead code elimination in OTP
- Link-time optimization (LTO)
- Alternative libcs (smaller than musl)

## Comparison with Standard Approaches

| Aspect | MicroBEAM | Container | Standard VM |
|--------|-----------|-----------|-------------|
| Size | 15-18MB | 50-200MB | 500MB-2GB |
| Boot Time | <200ms | 1-5s | 30-60s |
| Memory | 50MB | 100-500MB | 512MB-4GB |
| Complexity | High | Medium | Low |
| Flexibility | Low | Medium | High |

## Conclusion

MicroBEAM demonstrates that extreme minimization is possible while maintaining a functional Elixir environment. The architecture trades flexibility and ease of use for density and efficiency, making it suitable for specific use cases where these characteristics are valued above convenience.