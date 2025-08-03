# Installation Guide

This guide provides detailed instructions for installing and setting up the Vagrant Podman container.

## Prerequisites

Before installing the Vagrant Podman container, ensure you have the following prerequisites:

### 1. Podman Installation

Install Podman on your system:

**Ubuntu/Debian:**
```bash
# Add repository
. /etc/os-release
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key" | sudo apt-key add -

# Install Podman
sudo apt-get update
sudo apt-get install -y podman
```

**CentOS/RHEL/Fedora:**
```bash
# Install Podman
sudo dnf install -y podman
```

**macOS:**
```bash
# Using Homebrew
brew install podman

# Initialize Podman
podman machine init
podman machine start
```

### 2. Libvirt Installation

Install and configure libvirt:

**Ubuntu/Debian:**
```bash
sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-dev
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
```

**CentOS/RHEL/Fedora:**
```bash
sudo dnf install -y qemu-kvm libvirt-daemon-system libvirt-dev
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
```

### 3. User Configuration

Add your user to the libvirt group:

```bash
sudo usermod -a -G libvirt $USER
sudo usermod -a -G kvm $USER
```

**Important:** Logout and login again for group changes to take effect.

## Installation Methods

### Method 1: Automated Installation (Recommended)

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd vagrant_container
   ```

2. **Build the container:**
   ```bash
   ./scripts/build.sh
   ```

3. **Install on your system:**
   ```bash
   ./scripts/install.sh
   ```

4. **Verify installation:**
   ```bash
   ./scripts/check-installation.sh
   ```

5. **Reload your shell:**
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

### Method 2: Manual Installation

1. **Build the container manually:**
   ```bash
   podman build -t vagrant-libvirt:latest .
   ```

2. **Add vagrant function to your shell profile:**
   
   For bash (`~/.bashrc`):
   ```bash
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

   For zsh (`~/.zshrc`):
   ```bash
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

3. **Reload your shell profile:**
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

### Method 3: Using Published Image

If the image is published to Docker Hub:

1. **Pull the image:**
   ```bash
   podman pull <username>/vagrant-libvirt:latest
   ```

2. **Install using the install script:**
   ```bash
   ./scripts/install.sh -i <username>/vagrant-libvirt -t latest
   ```

## Configuration

### Environment Variables

The following environment variables can be configured:

- `LIBVIRT_DEFAULT_URI`: Libvirt connection URI (default: `qemu:///session`)
- `VAGRANT_HOME`: Vagrant home directory (default: `/.vagrant.d`)

### Volume Mounts

The container mounts the following volumes:

- `/var/run/libvirt/` → Host libvirt socket
- `~/.vagrant.d` → Vagrant configuration and boxes
- `${PWD}` → Current working directory for Vagrantfiles

### Network Configuration

The container uses host networking (`--network host`) to access libvirt and provide network connectivity to VMs.

## Verification

After installation, verify that everything is working:

1. **Check vagrant function:**
   ```bash
   type vagrant
   ```

2. **Test vagrant version:**
   ```bash
   vagrant --version
   ```

3. **List installed plugins:**
   ```bash
   vagrant plugin list
   ```

4. **Test libvirt connection:**
   ```bash
   virsh -c qemu:///session list
   ```

## Troubleshooting

### Common Issues

1. **Permission denied errors:**
   ```bash
   # Add user to libvirt group
   sudo usermod -a -G libvirt $USER
   
   # Restart libvirt
   sudo systemctl restart libvirtd
   
   # Logout and login again
   ```

2. **Container network issues:**
   - Ensure `--network host` is used
   - Check firewall settings
   - Verify libvirt network configuration

3. **Plugin loading errors:**
   - Rebuild the container: `./scripts/build.sh`
   - Check Ruby version compatibility
   - Verify plugin installation in container

4. **Function not found:**
   - Reload shell profile: `source ~/.bashrc`
   - Check if function was added to correct profile
   - Verify function syntax

### Debug Mode

Run vagrant with debug output:

```bash
vagrant --debug up
```

### Container Debugging

Run the container directly for debugging:

```bash
podman run -it --rm \
  -e VAGRANT_LOG=debug \
  -v /var/run/libvirt/:/var/run/libvirt/ \
  -v ~/.vagrant.d:/.vagrant.d \
  -v $(realpath "${PWD}"):${PWD} \
  -w "${PWD}" \
  --network host \
  vagrant-libvirt:latest
```

## Uninstallation

To uninstall the Vagrant Podman container:

1. **Remove vagrant function from shell profile:**
   ```bash
   # Edit your shell profile and remove the vagrant() function
   nano ~/.bashrc  # or ~/.zshrc
   ```

2. **Remove container image:**
   ```bash
   podman rmi vagrant-libvirt:latest
   ```

3. **Clean up Vagrant data (optional):**
   ```bash
   rm -rf ~/.vagrant.d
   ```

## Next Steps

After successful installation:

1. **Create your first Vagrantfile:**
   ```bash
   vagrant init generic/ubuntu2204
   ```

2. **Start your first VM:**
   ```bash
   vagrant up
   ```

3. **SSH into the VM:**
   ```bash
   vagrant ssh
   ```

4. **Explore examples:**
   ```bash
   cp examples/basic-vagrantfile Vagrantfile
   vagrant up
   ```

For more information, see the [Usage Guide](usage.md) and [Troubleshooting Guide](troubleshooting.md). 