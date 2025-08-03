# Vagrant Podman Container

A Podman container image that provides Vagrant with libvirt, ignition, and env plugins for consistent development environments.

## Overview

This repository provides a complete solution for running Vagrant with multiple plugins in a Podman container, eliminating compatibility issues between Ruby runtime environments and library dependencies. The container includes:

- **Vagrant** - Latest stable version
- **vagrant-libvirt** - Libvirt provider for Vagrant
- **vagrant-ignition** - Ignition provider for Vagrant  
- **vagrant-env** - Environment variable management for Vagrant

## Features

- **Consistent Environment**: Eliminates Ruby runtime compatibility issues
- **Multi-Plugin Support**: Pre-installed plugins for libvirt, ignition, and env
- **Easy Installation**: Simple scripts for building, publishing, and installing
- **Host Integration**: Seamless integration with host libvirt and file systems
- **Rootless Support**: Works with Podman's rootless mode

## Repository Structure

```
vagrant_container/
├── README.md                    # This file
├── Dockerfile                   # Container image definition
├── scripts/
│   ├── build.sh                # Build the container image
│   ├── publish.sh              # Publish to Docker Hub
│   ├── install.sh              # Install on local machine
│   └── check-installation.sh   # Verify installation
├── examples/
│   ├── basic-vagrantfile       # Basic Vagrantfile example
│   └── ignition-vagrantfile    # Ignition provider example
└── docs/
    ├── installation.md          # Detailed installation guide
    ├── usage.md                # Usage examples
    └── troubleshooting.md      # Common issues and solutions
```

## Quick Start

### 1. Build the Container

```bash
./scripts/build.sh
```

### 2. Install on Local Machine

```bash
./scripts/install.sh
```

### 3. Verify Installation

```bash
./scripts/check-installation.sh
```

### 4. Use Vagrant

```bash
# Check status
vagrant status

# Start a VM
vagrant up

# SSH into VM
vagrant ssh
```

## Installation Methods

### Method 1: Automated Installation (Recommended)

```bash
git clone <repository-url>
cd vagrant_container
./scripts/install.sh
```

### Method 2: Manual Installation

1. **Build the container:**
   ```bash
   ./scripts/build.sh
   ```

2. **Add vagrant function to your shell profile:**
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   vagrant(){
     podman run -it --rm \
       -e LIBVIRT_DEFAULT_URI \
       -v /var/run/libvirt/:/var/run/libvirt/ \
       -v ~/.vagrant.d:/.vagrant.d \
       -v $(realpath "${PWD}"):${PWD} \
       -w "${PWD}" \
       --network host \
       --entrypoint /bin/bash \
       --security-opt label=disable \
       localhost/vagrant-libvirt:latest \
         vagrant $@
   }
   ```

3. **Reload your shell:**
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

## Platform-Specific Setup

### macOS with Homebrew

If you're using macOS with Homebrew, the installation script will automatically:

1. **Detect Homebrew libvirt installation**
2. **Use the correct libvirt socket path** (`/opt/homebrew/var/run/libvirt/`)
3. **Check if libvirt service is running**

**Prerequisites:**
```bash
# Install libvirt via Homebrew
brew install libvirt

# Start libvirt service
brew services start libvirt
```

**Installation:**
```bash
./scripts/install.sh
```

**Verification:**
```bash
./scripts/check-installation.sh
```

The script will automatically detect your libvirt installation and configure the appropriate mount paths for your system.

## Container Features

### Pre-installed Plugins

- **vagrant-libvirt**: Libvirt provider for KVM/QEMU virtualization
- **vagrant-ignition**: Ignition provider for CoreOS/Flatcar Linux
- **vagrant-env**: Environment variable management

### Volume Mounts

- `/var/run/libvirt/` → Host libvirt socket
- `~/.vagrant.d` → Vagrant configuration and boxes
- `${PWD}` → Current working directory for Vagrantfiles

### Environment Variables

- `LIBVIRT_DEFAULT_URI`: Libvirt connection URI (defaults to `qemu:///session`)

## Usage Examples

### Basic Libvirt VM

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
  end
end
```

### Ignition Provider

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "flatcar-stable-amd64"
  config.vm.provider :ignition do |ignition|
    ignition.config = "ignition.yaml"
  end
end
```

### Environment Variables

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.env.set :VM_MEMORY, "4096"
  config.env.set :VM_CPUS, "4"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = config.env.get(:VM_MEMORY)
    libvirt.cpus = config.env.get(:VM_CPUS)
  end
end
```

## Publishing

### Build and Publish to Docker Hub

```bash
# Set your Docker Hub username
export DOCKER_USERNAME="your-username"

# Build and publish
./scripts/publish.sh
```

### Manual Publishing

```bash
# Build
./scripts/build.sh

# Tag for Docker Hub
podman tag localhost/vagrant-libvirt:latest your-username/vagrant-libvirt:latest

# Push to Docker Hub
podman push your-username/vagrant-libvirt:latest
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure libvirt socket is accessible
   ```bash
   sudo usermod -a -G libvirt $USER
   ```

2. **Container Network Issues**: Use `--network host` flag

3. **Plugin Loading Errors**: Check Ruby version compatibility

### macOS-Specific Issues

1. **libvirt not found**: Install via Homebrew
   ```bash
   brew install libvirt
   brew services start libvirt
   ```

2. **Wrong libvirt socket path**: The installation script automatically detects Homebrew libvirt and uses `/opt/homebrew/var/run/libvirt/`

3. **libvirt service not running or in error state**: Start or restart the service
   ```bash
   brew services start libvirt
   # If that fails, try restarting:
   brew services restart libvirt
   ```

4. **Check installation status**:
   ```bash
   ./scripts/check-installation.sh
   ```

### Debug Mode

Run with debug output:

```bash
vagrant --debug up
```

## Development

### Building for Development

```bash
# Build with development tools
./scripts/build.sh --dev

# Run with additional debugging
podman run -it --rm \
  -e VAGRANT_LOG=debug \
  -v /var/run/libvirt/:/var/run/libvirt/ \
  -v ~/.vagrant.d:/.vagrant.d \
  -v $(realpath "${PWD}"):${PWD} \
  -w "${PWD}" \
  --network host \
  localhost/vagrant-libvirt:latest
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

[Add your license here]

## References

- [Vagrant Libvirt Documentation](https://vagrant-libvirt.github.io/vagrant-libvirt/installation.html#docker--podman)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Podman Documentation](https://docs.podman.io/)
