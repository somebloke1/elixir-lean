# MicroBEAM - Ultra-Minimal Elixir VM

MicroBEAM is an experimental ultra-minimal Linux VM architecture where the BEAM (Erlang VM) runs as PID 1, eliminating traditional init systems for maximum size reduction.

## Architecture Goals
- Total system size: 15-18MB
- Boot time: <200ms
- Memory usage: <50MB running
- Single Elixir application focus
- No shell access in production

## Directory Structure
```
microbeam/
├── kernel/          # Linux kernel configuration
├── beam-init/       # Custom PID 1 launcher
├── buildroot/       # Buildroot configuration
├── elixir-app/      # Sample Elixir application
├── scripts/         # Build automation
└── images/          # Output images
```

## Build Requirements
- Linux host system
- Buildroot 2023.11+
- Elixir 1.15+
- QEMU for testing
- 10GB free disk space