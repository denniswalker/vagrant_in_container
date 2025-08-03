#!/bin/bash

# Entrypoint script for Vagrant Podman container

set -e

# Function to check if we're running in rootless mode
check_rootless() {
    if [ "$(id -u)" -eq 0 ]; then
        echo "Warning: Running as root. Consider using rootless mode for better security."
    fi
}

# Function to setup environment
setup_environment() {
    # Set default libvirt URI if not provided
    if [ -z "$LIBVIRT_DEFAULT_URI" ]; then
        export LIBVIRT_DEFAULT_URI="qemu:///session"
    fi
    
    # Ensure vagrant home directory exists
    mkdir -p "$VAGRANT_HOME"
    
    # Set proper permissions
    if [ -d "/var/run/libvirt" ]; then
        # Ensure libvirt socket is accessible
        if [ -S "/var/run/libvirt/libvirt-sock" ]; then
            chmod 666 /var/run/libvirt/libvirt-sock 2>/dev/null || true
        fi
    fi
}

# Function to validate libvirt connection
validate_libvirt() {
    if command -v virsh >/dev/null 2>&1; then
        if ! virsh -c "$LIBVIRT_DEFAULT_URI" list >/dev/null 2>&1; then
            echo "Warning: Cannot connect to libvirt at $LIBVIRT_DEFAULT_URI"
            echo "Make sure libvirt is running and accessible"
        fi
    fi
}

# Function to show help
show_help() {
    cat << EOF
Vagrant Podman Container

Usage:
    vagrant [command] [options]

Available commands:
    vagrant status          - Show status of VMs
    vagrant up             - Start VMs
    vagrant halt           - Stop VMs
    vagrant destroy        - Destroy VMs
    vagrant ssh            - SSH into VM
    vagrant plugin list    - List installed plugins

Environment variables:
    LIBVIRT_DEFAULT_URI   - Libvirt connection URI (default: qemu:///session)
    VAGRANT_HOME          - Vagrant home directory (default: /.vagrant.d)

Volume mounts:
    /var/run/libvirt      - Libvirt socket directory
    ~/.vagrant.d          - Vagrant configuration and boxes
    \${PWD}               - Current working directory

Examples:
    vagrant status
    vagrant up
    vagrant ssh
EOF
}

# Main execution
main() {
    check_rootless
    setup_environment
    
    # Show help only if explicitly requested
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_help
        exit 0
    fi
    
    # If no arguments, show vagrant help
    if [ $# -eq 0 ]; then
        exec vagrant --help
        exit 0
    fi
    
    # Validate libvirt connection for relevant commands
    case "$1" in
        up|status|ssh|halt|destroy|reload|resume|suspend)
            validate_libvirt
            ;;
    esac
    
    # Execute vagrant command
    exec vagrant "$@"
}

# Run main function with all arguments
main "$@" 