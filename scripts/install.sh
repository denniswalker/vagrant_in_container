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
    
    # Check if we're on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_status "Detected macOS system"
        
        # Check if libvirt is installed via Homebrew
        if brew list libvirt >/dev/null 2>&1; then
            print_status "Found libvirt installed via Homebrew"
            libvirt_path="/opt/homebrew/var/run/libvirt/"
            
            # Check if the socket directory exists
            if [ -d "$libvirt_path" ]; then
                print_success "Homebrew libvirt socket directory found: $libvirt_path"
            else
                print_warning "Homebrew libvirt installed but socket directory not found at $libvirt_path"
                print_status "You may need to start libvirt: brew services start libvirt"
                libvirt_path="/var/run/libvirt/"  # Fallback to default
            fi
        else
            print_warning "libvirt not found via Homebrew. You may need to install it:"
            print_status "brew install libvirt"
            print_status "brew services start libvirt"
            libvirt_path="/var/run/libvirt/"  # Fallback to default
        fi
    else
        # Linux systems - use default path
        libvirt_path="/var/run/libvirt/"
        print_status "Using default libvirt path for Linux: $libvirt_path"
    fi
    
    echo "$libvirt_path"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if podman is installed
    if ! command -v podman >/dev/null 2>&1; then
        print_error "Podman is not installed. Please install Podman first."
        print_status "Installation instructions: https://podman.io/getting-started/installation"
        exit 1
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
    # Detect libvirt path
    local libvirt_path
    libvirt_path=$(detect_libvirt_path)
    
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
    echo "    -v ${libvirt_path}:/var/run/libvirt/ \\" >> "$SHELL_PROFILE"
    echo "    -v ~/.vagrant.d:/.vagrant.d \\" >> "$SHELL_PROFILE"
    echo "    -v \$(realpath \"\${PWD}\"):\${PWD} \\" >> "$SHELL_PROFILE"
    echo "    -w \"\${PWD}\" \\" >> "$SHELL_PROFILE"
    echo "    --network host \\" >> "$SHELL_PROFILE"
    echo "    --entrypoint /bin/bash \\" >> "$SHELL_PROFILE"
    echo "    --security-opt label=disable \\" >> "$SHELL_PROFILE"
    echo "    ${IMAGE_NAME}:${TAG} \\" >> "$SHELL_PROFILE"
    echo "      vagrant \$@" >> "$SHELL_PROFILE"
    echo "}" >> "$SHELL_PROFILE"
    
    print_success "Vagrant function added to $SHELL_PROFILE"
}

# Function to test installation
test_installation() {
    print_status "Testing installation..."
    
    # Source the shell profile to load the function
    if [ -f "$SHELL_PROFILE" ]; then
        source "$SHELL_PROFILE"
    fi
    
    # Test if vagrant function exists
    if type vagrant 2>/dev/null | grep -q "function"; then
        print_success "Vagrant function installed successfully"
        
        # Test basic functionality
        if vagrant --version >/dev/null 2>&1; then
            print_success "Vagrant function is working correctly"
        else
            print_warning "Vagrant function installed but may need libvirt setup"
        fi
    else
        print_error "Vagrant function not found after installation"
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
    check_existing_function
    create_vagrant_function
    test_installation
    show_post_installation
}

# Run main function
main 