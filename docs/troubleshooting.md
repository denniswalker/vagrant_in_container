# Troubleshooting Guide

This guide provides solutions for common issues encountered when using the Vagrant Podman container.

## Common Issues and Solutions

### 1. Vagrant Function Not Found

**Problem:** `vagrant: command not found` or vagrant is not recognized as a function.

**Solutions:**

1. **Reload shell profile:**
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

2. **Check if function exists:**
   ```bash
   type vagrant
   ```

3. **Reinstall the function:**
   ```bash
   ./scripts/install.sh
   ```

4. **Check shell profile manually:**
   ```bash
   grep -n "vagrant()" ~/.bashrc ~/.zshrc
   ```

### 2. Container Image Not Found

**Problem:** `Error: image vagrant-libvirt:latest not found`

**Solutions:**

1. **Build the image:**
   ```bash
   ./scripts/build.sh
   ```

2. **Check available images:**
   ```bash
   podman images
   ```

3. **Pull from registry (if published):**
   ```bash
   podman pull <username>/vagrant-libvirt:latest
   ```

### 3. Libvirt Connection Issues

**Problem:** `Failed to connect to libvirt` or permission denied errors.

**Solutions:**

1. **Add user to libvirt group:**
   ```bash
   sudo usermod -a -G libvirt $USER
   sudo usermod -a -G kvm $USER
   ```

2. **Restart libvirt service:**
   ```bash
   sudo systemctl restart libvirtd
   ```

3. **Check libvirt status:**
   ```bash
   sudo systemctl status libvirtd
   ```

4. **Test libvirt connection:**
   ```bash
   virsh -c qemu:///session list
   ```

5. **Logout and login again** for group changes to take effect.

### 4. Permission Denied Errors

**Problem:** Permission denied when accessing libvirt socket or other resources.

**Solutions:**

1. **Check socket permissions:**
   ```bash
   ls -la /var/run/libvirt/
   ```

2. **Fix socket permissions:**
   ```bash
   sudo chmod 666 /var/run/libvirt/libvirt-sock
   ```

3. **Check user groups:**
   ```bash
   groups $USER
   ```

4. **Restart libvirt with proper permissions:**
   ```bash
   sudo systemctl restart libvirtd
   ```

### 5. Container Network Issues

**Problem:** Container cannot access host network or libvirt.

**Solutions:**

1. **Ensure host networking is used:**
   ```bash
   # Check if --network host is in vagrant function
   type vagrant
   ```

2. **Check firewall settings:**
   ```bash
   sudo ufw status
   sudo iptables -L
   ```

3. **Test network connectivity:**
   ```bash
   podman run --rm --network host alpine ping -c 1 8.8.8.8
   ```

### 6. Plugin Loading Errors

**Problem:** `LoadError` or plugin not found errors.

**Solutions:**

1. **Rebuild container with plugins:**
   ```bash
   ./scripts/build.sh
   ```

2. **Check plugin installation in container:**
   ```bash
   podman run --rm vagrant-libvirt:latest vagrant plugin list
   ```

3. **Check Ruby version compatibility:**
   ```bash
   podman run --rm vagrant-libvirt:latest ruby --version
   ```

### 7. VM Creation Fails

**Problem:** `vagrant up` fails with various errors.

**Solutions:**

1. **Check libvirt resources:**
   ```bash
   virsh -c qemu:///session list --all
   virsh -c qemu:///session pool-list
   ```

2. **Check available memory:**
   ```bash
   free -h
   ```

3. **Check disk space:**
   ```bash
   df -h
   ```

4. **Enable debug mode:**
   ```bash
   vagrant --debug up
   ```

### 8. SSH Connection Issues

**Problem:** Cannot SSH into VM or SSH key issues.

**Solutions:**

1. **Check SSH configuration:**
   ```bash
   vagrant ssh-config
   ```

2. **Regenerate SSH keys:**
   ```bash
   vagrant ssh -- -o UserKnownHostsFile=/dev/null
   ```

3. **Check VM status:**
   ```bash
   vagrant status
   ```

4. **Check VM console:**
   ```bash
   virsh -c qemu:///session console <vm-name>
   ```

### 9. Synced Folder Issues

**Problem:** Synced folders not working or permission issues.

**Solutions:**

1. **Check folder permissions:**
   ```bash
   ls -la /vagrant
   ```

2. **Recreate synced folder:**
   ```bash
   vagrant reload
   ```

3. **Check mount points:**
   ```bash
   vagrant ssh -- df -h
   ```

### 10. Box Download Issues

**Problem:** Cannot download Vagrant boxes.

**Solutions:**

1. **Check internet connectivity:**
   ```bash
   podman run --rm --network host alpine ping -c 1 8.8.8.8
   ```

2. **Use different box source:**
   ```bash
   vagrant box add generic/ubuntu2204 --provider libvirt
   ```

3. **Check box cache:**
   ```bash
   ls -la ~/.vagrant.d/boxes/
   ```

## Debugging Techniques

### 1. Enable Debug Mode

```bash
# Enable Vagrant debug output
vagrant --debug up

# Enable container debug output
VAGRANT_LOG=debug vagrant up
```

### 2. Run Container Directly

```bash
# Run container with debug environment
podman run -it --rm \
  -e VAGRANT_LOG=debug \
  -e LIBVIRT_DEFAULT_URI=qemu:///session \
  -v /var/run/libvirt/:/var/run/libvirt/ \
  -v ~/.vagrant.d:/.vagrant.d \
  -v $(realpath "${PWD}"):${PWD} \
  -w "${PWD}" \
  --network host \
  vagrant-libvirt:latest
```

### 3. Check Container Logs

```bash
# Get container ID
podman ps -a

# Check container logs
podman logs <container-id>

# Execute commands in container
podman exec -it <container-id> bash
```

### 4. Check System Resources

```bash
# Check memory usage
free -h

# Check disk space
df -h

# Check CPU usage
top

# Check libvirt processes
ps aux | grep libvirt
```

### 5. Network Diagnostics

```bash
# Check network interfaces
ip addr show

# Check libvirt networks
virsh -c qemu:///session net-list --all

# Test network connectivity
ping -c 1 8.8.8.8
```

## System-Specific Issues

### Ubuntu/Debian

**Problem:** Package conflicts or missing dependencies.

**Solutions:**

1. **Update package lists:**
   ```bash
   sudo apt-get update
   ```

2. **Install missing dependencies:**
   ```bash
   sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-dev
   ```

3. **Check KVM support:**
   ```bash
   kvm-ok
   ```

### CentOS/RHEL/Fedora

**Problem:** SELinux or firewall issues.

**Solutions:**

1. **Check SELinux status:**
   ```bash
   getenforce
   ```

2. **Temporarily disable SELinux:**
   ```bash
   sudo setenforce 0
   ```

3. **Check firewall rules:**
   ```bash
   sudo firewall-cmd --list-all
   ```

### macOS

**Problem:** Podman machine issues or networking problems.

**Solutions:**

1. **Initialize Podman machine:**
   ```bash
   podman machine init
   podman machine start
   ```

2. **Check machine status:**
   ```bash
   podman machine list
   ```

3. **Reset Podman machine:**
   ```bash
   podman machine stop
   podman machine rm
   podman machine init
   podman machine start
   ```

## Performance Issues

### 1. Slow VM Startup

**Solutions:**

1. **Use SSD storage:**
   ```bash
   # Check disk type
   lsblk -d -o name,rota
   ```

2. **Increase memory allocation:**
   ```ruby
   # In Vagrantfile
   config.vm.provider :libvirt do |libvirt|
     libvirt.memory = 4096  # Increase from 2048
   end
   ```

3. **Use virtio drivers:**
   ```ruby
   # In Vagrantfile
   config.vm.provider :libvirt do |libvirt|
     libvirt.disk_bus = "virtio"
     libvirt.nic_model_type = "virtio"
   end
   ```

### 2. High Memory Usage

**Solutions:**

1. **Monitor memory usage:**
   ```bash
   watch -n 1 'free -h'
   ```

2. **Limit container memory:**
   ```bash
   # Add memory limit to vagrant function
   podman run --memory=2g ...
   ```

3. **Clean up unused resources:**
   ```bash
   podman system prune -a
   ```

## Recovery Procedures

### 1. Reset Vagrant Environment

```bash
# Remove all VMs
vagrant destroy --force

# Remove all boxes
vagrant box list | awk '{print $1}' | xargs -I {} vagrant box remove {}

# Clean Vagrant data
rm -rf ~/.vagrant.d
```

### 2. Reset Libvirt Environment

```bash
# Stop all VMs
virsh -c qemu:///session list --all | grep running | awk '{print $2}' | xargs -I {} virsh -c qemu:///session destroy {}

# Remove all VMs
virsh -c qemu:///session list --all | awk '{print $2}' | xargs -I {} virsh -c qemu:///session undefine {}

# Restart libvirt
sudo systemctl restart libvirtd
```

### 3. Reset Container Environment

```bash
# Remove all containers
podman rm -a

# Remove all images
podman rmi -a

# Clean up system
podman system prune -a
```

## Getting Help

### 1. Check Logs

```bash
# Vagrant logs
vagrant --debug up 2>&1 | tee vagrant.log

# Container logs
podman logs <container-id> > container.log

# System logs
journalctl -u libvirtd -f
```

### 2. Community Resources

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Vagrant Libvirt Documentation](https://vagrant-libvirt.github.io/vagrant-libvirt/)
- [Podman Documentation](https://docs.podman.io/)
- [Libvirt Documentation](https://libvirt.org/docs.html)

### 3. Report Issues

When reporting issues, include:

1. **System information:**
   ```bash
   uname -a
   podman --version
   vagrant --version
   ```

2. **Error messages and logs**

3. **Steps to reproduce**

4. **Expected vs actual behavior**

### 4. Emergency Recovery

If all else fails:

```bash
# Complete reset
sudo systemctl stop libvirtd
sudo rm -rf /var/lib/libvirt/
sudo systemctl start libvirtd
rm -rf ~/.vagrant.d
./scripts/build.sh
./scripts/install.sh
```

This should restore a clean working environment. 