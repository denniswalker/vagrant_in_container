#!/bin/bash

# Check installation script for Vagrant Podman container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check libvirt installation
check_libvirt_installation() {
    print_status "Checking libvirt installation..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_status "Detected macOS system"
        
        # Check if Homebrew is installed
        if ! command -v brew >/dev/null 2>&1; then
            print_error "Homebrew is not installed. Please install Homebrew first:"
            print_status "https://brew.sh/"
            return 1
        fi
        
        # Check if libvirt is installed via Homebrew
        if brew list libvirt >/dev/null 2>&1; then
            print_success "libvirt is installed via Homebrew"
            
            # Check if libvirt service is running
            local service_status
            service_status=$(brew services list | grep "libvirt" | awk '{print $2}')
            if [ "$service_status" = "started" ]; then
                print_success "libvirt service is running"
            elif [ "$service_status" = "error" ]; then
                print_warning "libvirt service is in error state"
                print_status "Try restarting: brew services restart libvirt"
            else
                print_warning "libvirt service is not running"
                print_status "Start it with: brew services start libvirt"
            fi
            
            # Check socket directory
            local socket_dir="/opt/homebrew/var/run/libvirt/"
            if [ -d "$socket_dir" ]; then
                print_success "libvirt socket directory exists: $socket_dir"
                
                # Check for socket files
                local socket_count=$(find "$socket_dir" -name "*.sock" 2>/dev/null | wc -l)
                if [ "$socket_count" -gt 0 ]; then
                    print_success "Found $socket_count libvirt socket file(s)"
                else
                    print_warning "No libvirt socket files found"
                fi
            else
                print_warning "libvirt socket directory not found at $socket_dir"
            fi
            
        else
            print_error "libvirt is not installed via Homebrew"
            print_status "Install it with: brew install libvirt"
            print_status "Then start it with: brew services start libvirt"
            return 1
        fi
        
    else
        # Linux systems
        print_status "Detected Linux system"
        
        # Check if libvirt is installed
        if command -v virsh >/dev/null 2>&1; then
            print_success "libvirt is installed"
            
            # Check if libvirt service is running
            if systemctl is-active --quiet libvirtd; then
                print_success "libvirt service is running"
            else
                print_warning "libvirt service is not running"
                print_status "Start it with: sudo systemctl start libvirtd"
            fi
            
            # Check socket directory
            local socket_dir="/var/run/libvirt/"
            if [ -d "$socket_dir" ]; then
                print_success "libvirt socket directory exists: $socket_dir"
            else
                print_warning "libvirt socket directory not found at $socket_dir"
            fi
            
        else
            print_error "libvirt is not installed"
            print_status "Install it with your package manager (e.g., apt install libvirt-daemon-system)"
            return 1
        fi
    fi
}

# Function to check Podman installation
check_podman_installation() {
    print_status "Checking Podman installation..."
    
    if command -v podman >/dev/null 2>&1; then
        print_success "Podman is installed"
        
        # Check Podman version
        local version
        version=$(podman --version)
        print_status "Podman version: $version"
        
        # Check if Podman can run containers
        if podman info >/dev/null 2>&1; then
            print_success "Podman is working correctly"
        else
            print_warning "Podman is installed but may have configuration issues"
        fi
        
    else
        print_error "Podman is not installed"
        print_status "Installation instructions: https://podman.io/getting-started/installation"
        return 1
    fi
}

# Function to check Vagrant container image
check_vagrant_image() {
    print_status "Checking Vagrant container image..."
    
    local image_name="${1:-vagrant-libvirt}"
    local tag="${2:-latest}"
    
    if podman image exists "${image_name}:${tag}"; then
        print_success "Vagrant container image exists: ${image_name}:${tag}"
        
        # Test the container
        if podman run --rm "${image_name}:${tag}" vagrant --version >/dev/null 2>&1; then
            print_success "Vagrant container is working correctly"
        else
            print_warning "Vagrant container exists but may have issues"
        fi
        
    else
        print_warning "Vagrant container image not found: ${image_name}:${tag}"
        print_status "Build it with: ./scripts/build.sh"
        return 1
    fi
}

# Function to check shell function
check_shell_function() {
    print_status "Checking vagrant shell function..."
    
    if type vagrant 2>/dev/null | grep -q "function"; then
        print_success "vagrant function is defined in shell"
        
        # Test the function
        if vagrant --version >/dev/null 2>&1; then
            print_success "vagrant function is working correctly"
        else
            print_warning "vagrant function exists but may have issues"
        fi
        
    else
        print_warning "vagrant function is not defined"
        print_status "Install it with: ./scripts/install.sh"
        return 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Check the installation status of the Vagrant Podman container.

OPTIONS:
    -i, --image IMAGE       Image name to check (default: vagrant-libvirt)
    -t, --tag TAG           Image tag to check (default: latest)
    -h, --help              Show this help message

EXAMPLES:
    $0                      # Check all components
    $0 -i my-vagrant       # Check with custom image name
    $0 -t v1.0.0           # Check with specific tag

EOF
}

# Default values
IMAGE_NAME="vagrant-libvirt"
TAG="latest"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_status "Starting installation check..."
    echo
    
    local all_good=true
    
    # Check each component
    if ! check_libvirt_installation; then
        all_good=false
    fi
    echo
    
    if ! check_podman_installation; then
        all_good=false
    fi
    echo
    
    if ! check_vagrant_image "$IMAGE_NAME" "$TAG"; then
        all_good=false
    fi
    echo
    
    if ! check_shell_function; then
        all_good=false
    fi
    echo
    
    if [ "$all_good" = true ]; then
        print_success "All checks passed! Your Vagrant Podman container is ready to use."
    else
        print_warning "Some checks failed. Please address the issues above."
        exit 1
    fi
}

# Run main function
main 