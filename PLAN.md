# Vagrant Podman Container - Complete Plan

## Overview

This repository provides a complete solution for running Vagrant with multiple plugins in a Podman container, eliminating compatibility issues between Ruby runtime environments and library dependencies. The solution is based on the reference implementation from [Vagrant Libvirt Documentation](https://vagrant-libvirt.github.io/vagrant-libvirt/installation.html#docker--podman).

## Repository Structure

```
vagrant_container/
├── README.md                    # Comprehensive documentation
├── Dockerfile                   # Container image definition
├── entrypoint.sh               # Container entrypoint script
├── scripts/
│   ├── build.sh                # Build the container image
│   ├── publish.sh              # Publish to Docker Hub
│   ├── install.sh              # Install on local machine
│   └── check-installation.sh   # Verify installation
├── examples/
│   ├── basic-vagrantfile       # Basic Vagrantfile example
│   └── ignition-vagrantfile    # Ignition provider example
├── docs/
│   ├── installation.md          # Detailed installation guide
│   ├── usage.md                # Usage examples
│   └── troubleshooting.md      # Common issues and solutions
└── PLAN.md                     # This file
```

## Key Features

### 1. Container Image (`Dockerfile`)
- **Base Image**: Ubuntu 22.04 for better compatibility
- **Vagrant**: Latest stable version from HashiCorp repository
- **Pre-installed Plugins**:
  - `vagrant-libvirt`: Libvirt provider for KVM/QEMU
  - `vagrant-ignition`: Ignition provider for CoreOS/Flatcar
  - `vagrant-env`: Environment variable management
- **Security**: Non-root user for better security
- **Dependencies**: All required Ruby gems and system packages

### 2. Build System (`scripts/build.sh`)
- **Prerequisites Check**: Validates Podman installation and required files
- **Flexible Build**: Supports custom image names, tags, and development mode
- **Verification**: Tests built image functionality
- **User-Friendly**: Colored output and helpful error messages

### 3. Installation System (`scripts/install.sh`)
- **Automated Installation**: Detects shell type and installs vagrant function
- **Function Creation**: Adds vagrant function to shell profile
- **Conflict Resolution**: Handles existing vagrant installations
- **Verification**: Tests installation and provides feedback

### 4. Publishing System (`scripts/publish.sh`)
- **Docker Hub Integration**: Builds and publishes to Docker Hub
- **User Scripts**: Generates installation scripts for end users
- **Registry Support**: Configurable registry URLs
- **Verification**: Tests published image accessibility

### 5. Verification System (`scripts/check-installation.sh`)
- **Comprehensive Checks**: Validates all installation components
- **Function Detection**: Checks if vagrant is properly defined as a function
- **Plugin Verification**: Ensures all required plugins are installed
- **Troubleshooting**: Provides helpful error messages and solutions

## Installation Methods

### Method 1: Automated Installation (Recommended)
```bash
git clone <repository-url>
cd vagrant_container
./scripts/build.sh
./scripts/install.sh
./scripts/check-installation.sh
```

### Method 2: Manual Installation
```bash
# Build container
podman build -t vagrant-libvirt:latest .

# Add vagrant function to shell profile
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
    vagrant-libvirt:latest \
      vagrant $@
}
```

### Method 3: Using Published Image
```bash
# Pull from Docker Hub
podman pull <username>/vagrant-libvirt:latest

# Install using script
./scripts/install.sh -i <username>/vagrant-libvirt -t latest
```

## Container Features

### Volume Mounts
- `/var/run/libvirt/` → Host libvirt socket
- `~/.vagrant.d` → Vagrant configuration and boxes
- `${PWD}` → Current working directory for Vagrantfiles

### Environment Variables
- `LIBVIRT_DEFAULT_URI`: Libvirt connection URI (default: `qemu:///session`)
- `VAGRANT_HOME`: Vagrant home directory (default: `/.vagrant.d`)

### Network Configuration
- Uses host networking (`--network host`) for libvirt access
- Supports both rootless and rootful Podman modes

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

## Publishing Workflow

### 1. Build and Publish
```bash
# Set Docker Hub username
export DOCKER_USERNAME="your-username"

# Build and publish
./scripts/publish.sh -u your-username
```

### 2. User Installation
Users can install the published image:
```bash
# Pull image
podman pull your-username/vagrant-libvirt:latest

# Install using generated script
./install-your-username-vagrant-libvirt.sh
```

## Troubleshooting

### Common Issues
1. **Vagrant function not found**: Run `./scripts/install.sh`
2. **Container image missing**: Run `./scripts/build.sh`
3. **Libvirt connection fails**: Add user to libvirt group and restart service
4. **Plugin loading errors**: Rebuild container with `./scripts/build.sh`

### Debug Commands
```bash
# Check installation
./scripts/check-installation.sh --verbose

# Debug vagrant
vagrant --debug up

# Run container directly
podman run -it --rm vagrant-libvirt:latest vagrant --version
```

## Benefits

### 1. Consistency
- Eliminates Ruby runtime compatibility issues
- Provides consistent environment across different systems
- Pre-installed plugins ensure functionality

### 2. Ease of Use
- Simple installation process
- Automated setup scripts
- Comprehensive documentation

### 3. Flexibility
- Supports multiple installation methods
- Configurable for different use cases
- Extensible for additional plugins

### 4. Security
- Non-root container user
- Proper volume mounting
- Network isolation when needed

## Future Enhancements

### 1. Additional Plugins
- Support for more Vagrant plugins
- Plugin version management
- Custom plugin installation

### 2. Multi-Architecture Support
- ARM64 support
- Multi-platform builds
- Architecture-specific optimizations

### 3. CI/CD Integration
- Automated builds
- Testing pipeline
- Release automation

### 4. Advanced Features
- Plugin management interface
- Configuration validation
- Performance monitoring

## Conclusion

This comprehensive plan provides a complete solution for running Vagrant with libvirt, ignition, and env plugins in a Podman container. The solution addresses compatibility issues, provides easy installation, and includes extensive documentation and troubleshooting guides.

The implementation follows best practices for containerization, security, and user experience, making it suitable for both individual developers and enterprise environments. 