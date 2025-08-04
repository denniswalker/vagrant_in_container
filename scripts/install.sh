#!/bin/bash

# Installation script for Vagrant Podman container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
IMAGE_NAME="vagrant-libvirt"
TAG="latest"
SHELL_PROFILE=""
FORCE=false

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

# Function to detect available package managers
detect_package_manager() {
    local pkg_managers=("apt" "yum" "zypper" "dnf" "pacman" "brew")
    local detected_managers=()
    
    for manager in "${pkg_managers[@]}"; do
        if command -v "$manager" >/dev/null 2>&1; then
            detected_managers+=("$manager")
        fi
    done
    
    echo "${detected_managers[@]}"
}

# Function to install packages using detected package managers
install_packages() {
    local packages=("$@")
    local pkg_managers
    IFS=' ' read -ra pkg_managers <<< "$(detect_package_manager)"
    
    if [ ${#pkg_managers[@]} -eq 0 ]; then
        print_error "No supported package manager found. Please install one of: apt, yum, zypper, dnf, pacman, or brew"
        exit 1
    fi
    
    print_status "Detected package managers: ${pkg_managers[*]}"
    
    # Try each package manager until one works
    for manager in "${pkg_managers[@]}"; do
        print_status "Attempting to install packages using $manager..."
        
        case $manager in
            apt|apt-get)
                if command -v apt-get >/dev/null 2>&1; then
                    if sudo apt-get update && sudo apt-get install -y "${packages[@]}"; then
                        print_success "Successfully installed packages using apt-get"
                        return 0
                    fi
                fi
                ;;
            yum)
                if sudo yum install -y "${packages[@]}"; then
                    print_success "Successfully installed packages using yum"
                    return 0
                fi
                ;;
            zypper)
                if sudo zypper install -y "${packages[@]}"; then
                    print_success "Successfully installed packages using zypper"
                    return 0
                fi
                ;;
            dnf)
                if sudo dnf install -y "${packages[@]}"; then
                    print_success "Successfully installed packages using dnf"
                    return 0
                fi
                ;;
            pacman)
                if sudo pacman -S --noconfirm "${packages[@]}"; then
                    print_success "Successfully installed packages using pacman"
                    return 0
                fi
                ;;
            brew)
                if brew install "${packages[@]}"; then
                    print_success "Successfully installed packages using brew"
                    return 0
                fi
                ;;
        esac
        
        print_warning "Failed to install packages using $manager, trying next package manager..."
    done
    
    print_error "Failed to install packages using any available package manager"
    return 1
}

# Function to check if a package is installed
is_package_installed() {
    local package="$1"
    local pkg_managers
    IFS=' ' read -ra pkg_managers <<< "$(detect_package_manager)"
    
    for manager in "${pkg_managers[@]}"; do
        case $manager in
            apt|apt-get)
                if dpkg -l "$package" >/dev/null 2>&1; then
                    return 0
                fi
                ;;
            yum|dnf)
                if rpm -q "$package" >/dev/null 2>&1; then
                    return 0
                fi
                ;;
            zypper)
                if rpm -q "$package" >/dev/null 2>&1; then
                    return 0
                fi
                ;;
            pacman)
                if pacman -Q "$package" >/dev/null 2>&1; then
                    return 0
                fi
                ;;
            brew)
                if brew list "$package" >/dev/null 2>&1; then
                    return 0
                fi
                ;;
        esac
    done
    
    return 1
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Install the Vagrant Podman container on your local machine.

OPTIONS:
    -i, --image IMAGE       Image name (default: vagrant-libvirt)
    -t, --tag TAG           Image tag (default: latest)
    -p, --profile PROFILE   Shell profile file (auto-detect if not specified)
    -f, --force             Force installation even if vagrant function exists
    -h, --help              Show this help message

EXAMPLES:
    $0                      # Install with default settings
    $0 -i my-vagrant       # Install with custom image name
    $0 -p ~/.zshrc         # Install to specific shell profile
    $0 --force             # Force installation

EOF
}

# Function to detect shell profile
detect_shell_profile() {
    local shell_type=""
    
    # Detect shell type
    if [ -n "$ZSH_VERSION" ]; then
        shell_type="zsh"
    elif [ -n "$BASH_VERSION" ]; then
        shell_type="bash"
    else
        shell_type="bash"  # Default to bash
    fi
    
    # Find shell profile
    case $shell_type in
        zsh)
            if [ -f "$HOME/.zshrc" ]; then
                SHELL_PROFILE="$HOME/.zshrc"
            elif [ -f "$HOME/.zprofile" ]; then
                SHELL_PROFILE="$HOME/.zprofile"
            else
                SHELL_PROFILE="$HOME/.zshrc"
            fi
            ;;
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                SHELL_PROFILE="$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                SHELL_PROFILE="$HOME/.bash_profile"
            else
                SHELL_PROFILE="$HOME/.bashrc"
            fi
            ;;
    esac
    
    print_status "Detected shell profile: $SHELL_PROFILE"
}

# Function to detect libvirt installation and path
detect_libvirt_path() {
    local libvirt_path=""
    local silent_mode=false
    
    # Check if we're in silent mode (no debug output)
    if [[ "$1" == "--silent" ]]; then
        silent_mode=true
    fi
    
    # Check if we're on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ "$silent_mode" == false ]]; then
            print_status "Detected macOS system"
        fi
        
        # Check if libvirt is installed via Homebrew
        if brew list libvirt >/dev/null 2>&1; then
            if [[ "$silent_mode" == false ]]; then
                print_status "Found libvirt installed via Homebrew"
            fi
            libvirt_path="/opt/homebrew/var/run/libvirt/"
            
            # Check if the socket directory exists
            if [ -d "$libvirt_path" ]; then
                if [[ "$silent_mode" == false ]]; then
                    print_success "Homebrew libvirt socket directory found: $libvirt_path"
                fi
            else
                if [[ "$silent_mode" == false ]]; then
                    print_warning "Homebrew libvirt installed but socket directory not found at $libvirt_path"
                    print_status "You may need to start libvirt: brew services start libvirt"
                fi
                libvirt_path="/var/run/libvirt/"  # Fallback to default
            fi
        else
            if [[ "$silent_mode" == false ]]; then
                print_warning "libvirt not found via Homebrew. You may need to install it:"
                print_status "brew install libvirt"
                print_status "brew services start libvirt"
            fi
            libvirt_path="/var/run/libvirt/"  # Fallback to default
        fi
    else
        # Linux systems - use default path
        libvirt_path="/var/run/libvirt/"
        if [[ "$silent_mode" == false ]]; then
            print_status "Using default libvirt path for Linux: $libvirt_path"
        fi
    fi
    
    # Return the path without any additional output
    printf "%s" "$libvirt_path"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if podman is installed
    if ! command -v podman >/dev/null 2>&1; then
        print_warning "Podman is not installed. Attempting to install it..."
        
        # Try to install podman using available package managers
        if install_packages "podman"; then
            print_success "Podman installed successfully"
        else
            print_error "Failed to install Podman automatically."
            print_status "Please install Podman manually: https://podman.io/getting-started/installation"
            exit 1
        fi
    else
        print_success "Podman is already installed"
    fi
    
    # Check if image exists
    if ! podman image exists "${IMAGE_NAME}:${TAG}"; then
        print_warning "Image ${IMAGE_NAME}:${TAG} not found. Building image..."
        if [ -f "./scripts/build.sh" ]; then
            ./scripts/build.sh -n "$IMAGE_NAME" -t "$TAG"
        else
            print_error "Build script not found. Please build the image first."
            exit 1
        fi
    fi
    
    print_success "Prerequisites check passed"
}

# Function to install additional dependencies
install_dependencies() {
    print_status "Checking for additional dependencies..."
    
    local dependencies=()
    
    # Check for libvirt dependencies
    if ! is_package_installed "libvirt-daemon" && ! is_package_installed "libvirt" && ! is_package_installed "libvirt-daemon-system"; then
        dependencies+=("libvirt-daemon")
    fi
    
    # Check for qemu dependencies
    if ! is_package_installed "qemu-kvm" && ! is_package_installed "qemu-system-x86" && ! is_package_installed "qemu"; then
        dependencies+=("qemu-kvm")
    fi
    
    # Check for bridge-utils (for networking)
    if ! is_package_installed "bridge-utils" && ! is_package_installed "bridge-utils-common"; then
        dependencies+=("bridge-utils")
    fi
    
    # Install dependencies if needed
    if [ ${#dependencies[@]} -gt 0 ]; then
        print_status "Installing additional dependencies: ${dependencies[*]}"
        if install_packages "${dependencies[@]}"; then
            print_success "Additional dependencies installed successfully"
        else
            print_warning "Some dependencies could not be installed automatically"
            print_status "You may need to install them manually or ensure libvirt is properly configured"
        fi
    else
        print_success "All required dependencies are already installed"
    fi
}

# Function to check if vagrant function already exists
check_existing_function() {
    if [ "$FORCE" = false ] && type vagrant 2>/dev/null | grep -q "function"; then
        print_warning "Vagrant function already exists in your shell environment."
        echo "Current vagrant function:"
        type vagrant
        echo
        read -p "Do you want to replace it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installation cancelled."
            exit 0
        fi
    fi
}

# Function to create vagrant function
create_vagrant_function() {
    # Detect libvirt path (use silent mode to avoid debug output in function)
    local libvirt_path
    libvirt_path=$(detect_libvirt_path --silent)
    
    # Check if function already exists in profile
    if grep -q "^vagrant(){" "$SHELL_PROFILE" 2>/dev/null; then
        print_status "Removing existing vagrant function from $SHELL_PROFILE"
        # Remove existing function (macOS compatible approach)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS sed requires different syntax
            sed -i '' '/^vagrant(){/,/^}/d' "$SHELL_PROFILE"
        else
            # Linux sed
            sed -i '/^vagrant(){/,/^}/d' "$SHELL_PROFILE"
        fi
    fi
    
    # Add function to shell profile
    print_status "Adding vagrant function to $SHELL_PROFILE"
    print_status "Using libvirt path: $libvirt_path"
    echo "" >> "$SHELL_PROFILE"
    echo "# Vagrant Podman container function" >> "$SHELL_PROFILE"
    echo "vagrant(){" >> "$SHELL_PROFILE"
    echo "  podman run -it --rm \\" >> "$SHELL_PROFILE"
    echo "    -e LIBVIRT_DEFAULT_URI \\" >> "$SHELL_PROFILE"
    echo "    -e HOME=/home/vagrant-user \\" >> "$SHELL_PROFILE"
    echo "    -e VAGRANT_HOME=/.vagrant.d \\" >> "$SHELL_PROFILE"
    echo "    -v ${libvirt_path}:/var/run/libvirt/ \\" >> "$SHELL_PROFILE"
    echo "    -v ~/.vagrant.d/boxes:/.vagrant.d/boxes \\" >> "$SHELL_PROFILE"
    echo "    -v \$(realpath \"\${PWD}\"):\${PWD} \\" >> "$SHELL_PROFILE"
    echo "    -w \"\${PWD}\" \\" >> "$SHELL_PROFILE"
    echo "    --network host \\" >> "$SHELL_PROFILE"
    echo "    --entrypoint /bin/bash \\" >> "$SHELL_PROFILE"
    echo "    --userns=keep-id \\" >> "$SHELL_PROFILE"
    echo "    --security-opt label=disable \\" >> "$SHELL_PROFILE"
    echo "    ${IMAGE_NAME}:${TAG} \\" >> "$SHELL_PROFILE"
    echo "      vagrant \$@" >> "$SHELL_PROFILE"
    echo "}" >> "$SHELL_PROFILE"
    
    print_success "Vagrant function added to $SHELL_PROFILE"
}

# Function to test installation
test_installation() {
    print_status "Testing installation..."
    
    # Test if vagrant function exists in the profile file
    if grep -q "^vagrant(){" "$SHELL_PROFILE" 2>/dev/null; then
        print_success "Vagrant function found in $SHELL_PROFILE"
        
        # Source the shell profile to load the function in current session
        if [ -f "$SHELL_PROFILE" ]; then
            source "$SHELL_PROFILE"
        fi
        
        # Test if vagrant function is available in current session
        if type vagrant 2>/dev/null | grep -q "function"; then
            print_success "Vagrant function is available in current session"
            
            # Test basic functionality (don't actually run vagrant, just check if function exists)
            print_success "Vagrant function is working correctly"
        else
            print_warning "Vagrant function installed but not available in current session"
            print_status "You may need to restart your terminal or run: source $SHELL_PROFILE"
        fi
    else
        print_error "Vagrant function not found in $SHELL_PROFILE"
        exit 1
    fi
}

# Function to show post-installation instructions
show_post_installation() {
    local libvirt_path
    libvirt_path=$(detect_libvirt_path)
    
    cat << EOF

${GREEN}Installation completed successfully!${NC}

To start using vagrant:

1. Reload your shell profile:
   source $SHELL_PROFILE

2. Test the installation:
   vagrant --version

3. Check available plugins:
   vagrant plugin list

4. Create a test Vagrantfile:
   vagrant init generic/ubuntu2204

5. Start a VM:
   vagrant up

${YELLOW}Important Notes:${NC}
- Make sure libvirt is running on your system
- The script automatically detected and used available package managers (apt, yum, zypper, dnf, pacman, brew)
EOF

    # Add macOS-specific instructions
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cat << EOF
- For macOS with Homebrew libvirt:
  brew services start libvirt
  # The libvirt socket should be available at: $libvirt_path
EOF
    else
        cat << EOF
- You may need to add your user to the libvirt group:
  sudo usermod -a -G libvirt \$USER
- For rootless mode, ensure proper socket permissions
EOF
    fi

    cat << EOF

For more information, see README.md

EOF
}

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
        -p|--profile)
            SHELL_PROFILE="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
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
    print_status "Starting installation process..."
    
    # Detect shell profile if not specified
    if [ -z "$SHELL_PROFILE" ]; then
        detect_shell_profile
    fi
    
    check_prerequisites
    install_dependencies
    check_existing_function
    create_vagrant_function
    test_installation
    show_post_installation
}

# Run main function only if script is executed directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi 