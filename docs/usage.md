# Usage Guide

This guide provides examples and best practices for using the Vagrant Podman container.

## Basic Usage

### Getting Started

1. **Check installation:**
   ```bash
   vagrant --version
   vagrant plugin list
   ```

2. **Create a new project:**
   ```bash
   mkdir my-vagrant-project
   cd my-vagrant-project
   vagrant init generic/ubuntu2204
   ```

3. **Start a VM:**
   ```bash
   vagrant up
   ```

4. **SSH into the VM:**
   ```bash
   vagrant ssh
   ```

5. **Stop the VM:**
   ```bash
   vagrant halt
   ```

6. **Destroy the VM:**
   ```bash
   vagrant destroy
   ```

## Provider-Specific Usage

### Libvirt Provider

The libvirt provider is the primary provider for KVM/QEMU virtualization.

#### Basic Libvirt Configuration

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
    libvirt.disk_bus = "virtio"
    libvirt.nic_model_type = "virtio"
  end
end
```

#### Advanced Libvirt Configuration

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  config.vm.provider :libvirt do |libvirt|
    # VM specifications
    libvirt.memory = 4096
    libvirt.cpus = 4
    libvirt.disk_bus = "virtio"
    libvirt.nic_model_type = "virtio"
    
    # Storage configuration
    libvirt.storage_pool_name = "default"
    libvirt.disk_size = "20G"
    
    # Network configuration
    libvirt.network_name = "default"
    libvirt.management_network_name = "default"
    libvirt.management_network_address = "192.168.121.0/24"
    
    # Graphics configuration
    libvirt.graphics_type = "vnc"
    libvirt.graphics_port = 5900
    libvirt.graphics_autoport = "yes"
    libvirt.graphics_listen = "0.0.0.0"
    
    # Additional settings
    libvirt.management_network_autostart = true
    libvirt.management_network_pci_bus = "0x06"
    libvirt.management_network_pci_slot = "0x01"
  end
  
  # Network configuration
  config.vm.network "private_network", ip: "192.168.121.10"
  
  # Synced folders
  config.vm.synced_folder ".", "/vagrant", disabled: false
end
```

### Ignition Provider

The ignition provider is used for CoreOS/Flatcar Linux systems.

#### Basic Ignition Configuration

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "flatcar-stable-amd64"
  
  config.vm.provider :ignition do |ignition|
    ignition.config = "ignition.yaml"
  end
  
  # Libvirt provider is still needed for the underlying VM
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 4096
    libvirt.cpus = 2
  end
end
```

#### Ignition Configuration File

Create an `ignition.yaml` file:

```yaml
variant: fcos
version: 1.4.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...
storage:
  files:
    - path: /etc/hostname
      mode: 0644
      contents:
        inline: my-flatcar-server
    - path: /etc/systemd/network/20-enp1s0.network
      mode: 0644
      contents:
        inline: |
          [Match]
          Name=enp1s0
          
          [Network]
          Address=192.168.121.11/24
          Gateway=192.168.121.1
          DNS=8.8.8.8
systemd:
  units:
    - name: docker.service
      enabled: true
    - name: sshd.service
      enabled: true
```

### Environment Variables Provider

The env provider allows you to use environment variables in your Vagrantfile.

#### Basic Environment Configuration

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  # Set environment variables
  config.env.set :VM_MEMORY, "4096"
  config.env.set :VM_CPUS, "2"
  config.env.set :VM_IP, "192.168.121.10"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = config.env.get(:VM_MEMORY)
    libvirt.cpus = config.env.get(:VM_CPUS)
  end
  
  config.vm.network "private_network", ip: config.env.get(:VM_IP)
end
```

#### Environment Variables from Shell

You can also use environment variables from your shell:

```bash
export VM_MEMORY=4096
export VM_CPUS=2
export VM_IP=192.168.121.10
```

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  # Use environment variables from shell
  config.env.set :VM_MEMORY, ENV['VM_MEMORY'] || "2048"
  config.env.set :VM_CPUS, ENV['VM_CPUS'] || "1"
  config.env.set :VM_IP, ENV['VM_IP'] || "192.168.121.10"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = config.env.get(:VM_MEMORY)
    libvirt.cpus = config.env.get(:VM_CPUS)
  end
  
  config.vm.network "private_network", ip: config.env.get(:VM_IP)
end
```

## Multi-Machine Configuration

### Basic Multi-Machine Setup

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  # Web server
  config.vm.define "web" do |web|
    web.vm.box = "generic/ubuntu2204"
    web.vm.hostname = "web-server"
    
    web.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
    end
    
    web.vm.network "private_network", ip: "192.168.121.10"
  end
  
  # Database server
  config.vm.define "db" do |db|
    db.vm.box = "generic/ubuntu2204"
    db.vm.hostname = "db-server"
    
    db.vm.provider :libvirt do |libvirt|
      libvirt.memory = 4096
      libvirt.cpus = 2
    end
    
    db.vm.network "private_network", ip: "192.168.121.11"
  end
end
```

### Multi-Machine with Shared Configuration

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  # Shared configuration
  config.vm.box = "generic/ubuntu2204"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.disk_bus = "virtio"
    libvirt.nic_model_type = "virtio"
  end
  
  # Web server
  config.vm.define "web" do |web|
    web.vm.hostname = "web-server"
    
    web.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
    end
    
    web.vm.network "private_network", ip: "192.168.121.10"
    
    web.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update
      sudo apt-get install -y nginx
      sudo systemctl enable nginx
      sudo systemctl start nginx
    SHELL
  end
  
  # Database server
  config.vm.define "db" do |db|
    db.vm.hostname = "db-server"
    
    db.vm.provider :libvirt do |libvirt|
      libvirt.memory = 4096
      libvirt.cpus = 2
    end
    
    db.vm.network "private_network", ip: "192.168.121.11"
    
    db.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update
      sudo apt-get install -y postgresql postgresql-contrib
      sudo systemctl enable postgresql
      sudo systemctl start postgresql
    SHELL
  end
end
```

## Provisioning

### Shell Provisioning

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
  end
  
  # Shell provisioning
  config.vm.provision "shell", inline: <<-SHELL
    # Update system
    sudo apt-get update
    sudo apt-get upgrade -y
    
    # Install packages
    sudo apt-get install -y curl wget git htop
    
    # Configure system
    sudo hostnamectl set-hostname my-server
    
    echo "Provisioning completed!"
  SHELL
end
```

### File Provisioning

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
  end
  
  # File provisioning
  config.vm.provision "file", source: "config/app.conf", destination: "/tmp/app.conf"
  
  config.vm.provision "shell", inline: <<-SHELL
    sudo mv /tmp/app.conf /etc/app.conf
    sudo chown root:root /etc/app.conf
    sudo chmod 644 /etc/app.conf
  SHELL
end
```

## Networking

### Private Network

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
  end
  
  # Private network with static IP
  config.vm.network "private_network", ip: "192.168.121.10"
  
  # Private network with DHCP
  config.vm.network "private_network", type: "dhcp"
end
```

### Public Network

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
  end
  
  # Public network (bridge)
  config.vm.network "public_network", bridge: "virbr0"
end
```

## Synced Folders

### Basic Synced Folder

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
  end
  
  # Synced folder
  config.vm.synced_folder ".", "/vagrant", disabled: false
end
```

### Multiple Synced Folders

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
  end
  
  # Multiple synced folders
  config.vm.synced_folder ".", "/vagrant", disabled: false
  config.vm.synced_folder "./data", "/data", disabled: false
  config.vm.synced_folder "./logs", "/var/log/app", disabled: false
end
```

## Best Practices

### 1. Use Environment Variables

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  # Use environment variables for configuration
  config.env.set :VM_MEMORY, ENV['VM_MEMORY'] || "2048"
  config.env.set :VM_CPUS, ENV['VM_CPUS'] || "2"
  config.env.set :VM_IP, ENV['VM_IP'] || "192.168.121.10"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = config.env.get(:VM_MEMORY)
    libvirt.cpus = config.env.get(:VM_CPUS)
  end
  
  config.vm.network "private_network", ip: config.env.get(:VM_IP)
end
```

### 2. Separate Configuration Files

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  # Load configuration from external file
  config_file = File.join(File.dirname(__FILE__), "config.rb")
  load config_file if File.exist?(config_file)
  
  config.vm.box = "generic/ubuntu2204"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
  end
end
```

```ruby
# config.rb
Vagrant.configure("2") do |config|
  config.vm.network "private_network", ip: "192.168.121.10"
  
  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y nginx
  SHELL
end
```

### 3. Use Box Versioning

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  config.vm.box_version = "4.2.16"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
  end
end
```

### 4. Implement Proper Cleanup

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
  end
  
  # Cleanup on destroy
  config.trigger.after :destroy do |trigger|
    trigger.run = {inline: "echo 'Cleaning up...'"}
  end
end
```

## Troubleshooting

### Common Commands

```bash
# Check VM status
vagrant status

# View VM details
vagrant global-status

# SSH into VM
vagrant ssh

# Reload VM
vagrant reload

# Suspend VM
vagrant suspend

# Resume VM
vagrant resume

# Destroy VM
vagrant destroy

# Force destroy
vagrant destroy --force
```

### Debug Commands

```bash
# Debug mode
vagrant --debug up

# Verbose output
vagrant up --debug

# Check libvirt connection
virsh -c qemu:///session list

# Check container logs
podman logs <container-id>
```

For more troubleshooting information, see the [Troubleshooting Guide](troubleshooting.md). 