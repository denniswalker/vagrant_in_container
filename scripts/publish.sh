#!/bin/bash

# Publish script for Vagrant Podman container

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
DOCKER_USERNAME=""
REGISTRY="docker.io"
PUSH=true
BUILD=true

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

Build and publish the Vagrant Podman container to Docker Hub.

OPTIONS:
    -u, --username USERNAME   Docker Hub username (required)
    -i, --image IMAGE         Image name (default: vagrant-libvirt)
    -t, --tag TAG             Image tag (default: latest)
    -r, --registry REGISTRY   Registry URL (default: docker.io)
    --no-build                Skip building the image
    --no-push                 Skip pushing to registry
    -h, --help                Show this help message

ENVIRONMENT VARIABLES:
    DOCKER_USERNAME           Docker Hub username
    DOCKER_PASSWORD           Docker Hub password/token
    DOCKER_EMAIL              Docker Hub email

EXAMPLES:
    $0 -u myusername                    # Build and push with default settings
    $0 -u myusername -t v1.0.0         # Build and push with specific tag
    $0 -u myusername --no-push          # Build only, don't push
    $0 -u myusername --no-build         # Push existing image only

EOF
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if podman is installed
    if ! command -v podman >/dev/null 2>&1; then
        print_error "Podman is not installed. Please install Podman first."
        exit 1
    fi
    
    # Check if Dockerfile exists
    if [ ! -f "Dockerfile" ]; then
        print_error "Dockerfile not found in current directory."
        exit 1
    fi
    
    # Check if username is provided
    if [ -z "$DOCKER_USERNAME" ]; then
        print_error "Docker Hub username is required."
        print_status "Set DOCKER_USERNAME environment variable or use -u option."
        exit 1
    fi
    
    # Check if logged in to registry
    if [ "$PUSH" = true ]; then
        if ! podman login --get-login "$REGISTRY" >/dev/null 2>&1; then
            print_warning "Not logged in to $REGISTRY"
            print_status "You may be prompted to login during push."
        fi
    fi
    
    print_success "Prerequisites check passed"
}

# Function to build image
build_image() {
    if [ "$BUILD" = true ]; then
        print_status "Building image: ${IMAGE_NAME}:${TAG}"
        
        if [ -f "./scripts/build.sh" ]; then
            ./scripts/build.sh -n "$IMAGE_NAME" -t "$TAG"
        else
            print_error "Build script not found. Please run build manually."
            exit 1
        fi
    else
        print_status "Skipping build (--no-build specified)"
    fi
}

# Function to tag image for registry
tag_image() {
    local registry_image="${REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
    
    print_status "Tagging image for registry: $registry_image"
    
    if podman tag "${IMAGE_NAME}:${TAG}" "$registry_image"; then
        print_success "Image tagged successfully"
    else
        print_error "Failed to tag image"
        exit 1
    fi
}

# Function to push image
push_image() {
    if [ "$PUSH" = true ]; then
        local registry_image="${REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
        
        print_status "Pushing image to registry: $registry_image"
        
        if podman push "$registry_image"; then
            print_success "Image pushed successfully"
        else
            print_error "Failed to push image"
            exit 1
        fi
    else
        print_status "Skipping push (--no-push specified)"
    fi
}

# Function to verify published image
verify_published_image() {
    if [ "$PUSH" = true ]; then
        local registry_image="${REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
        
        print_status "Verifying published image..."
        
        # Try to pull the image to verify it's accessible
        if podman pull "$registry_image" >/dev/null 2>&1; then
            print_success "Published image is accessible"
        else
            print_warning "Could not verify published image accessibility"
        fi
    fi
}

# Function to show published image info
show_published_info() {
    local registry_image="${REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
    
    cat << EOF

${GREEN}Image published successfully!${NC}

Registry: $REGISTRY
Image: $registry_image

To use the published image:

1. Pull the image:
   podman pull $registry_image

2. Install on another machine:
   ./scripts/install.sh -i ${DOCKER_USERNAME}/${IMAGE_NAME} -t ${TAG}

3. Run directly:
   podman run --rm $registry_image vagrant --version

${YELLOW}Installation Instructions for Users:${NC}

Users can install this image by running:
   git clone <repository-url>
   cd vagrant_container
   ./scripts/install.sh -i ${DOCKER_USERNAME}/${IMAGE_NAME} -t ${TAG}

EOF
}

# Function to create installation script for users
create_user_install_script() {
    local script_name="install-${DOCKER_USERNAME}-${IMAGE_NAME}.sh"
    
    cat > "$script_name" << EOF
#!/bin/bash

# Auto-generated installation script for ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}

set -e

IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}"
TAG="${TAG}"

echo "Installing Vagrant Podman container..."

# Check if podman is installed
if ! command -v podman >/dev/null 2>&1; then
    echo "Error: Podman is not installed. Please install Podman first."
    exit 1
fi

# Pull the image
echo "Pulling image: \${IMAGE_NAME}:\${TAG}"
podman pull "\${IMAGE_NAME}:\${TAG}"

# Detect shell profile
SHELL_PROFILE=""
if [ -n "\$ZSH_VERSION" ]; then
    SHELL_PROFILE="\$HOME/.zshrc"
elif [ -n "\$BASH_VERSION" ]; then
    SHELL_PROFILE="\$HOME/.bashrc"
fi

# Create vagrant function
cat >> "\$SHELL_PROFILE" << 'VAGRANT_FUNCTION'

# Vagrant Podman container function
vagrant(){
  podman run -it --rm \\
    -e LIBVIRT_DEFAULT_URI \\
    -v /var/run/libvirt/:/var/run/libvirt/ \\
    -v ~/.vagrant.d:/.vagrant.d \\
    -v \$(realpath "\${PWD}"):\${PWD} \\
    -w "\${PWD}" \\
    --network host \\
    --entrypoint /bin/bash \\
    --security-opt label=disable \\
    ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} \\
      vagrant \$@
}
VAGRANT_FUNCTION

echo "Installation completed!"
echo "Please reload your shell profile: source \$SHELL_PROFILE"
echo "Then test with: vagrant --version"
EOF
    
    chmod +x "$script_name"
    print_success "Created user installation script: $script_name"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            DOCKER_USERNAME="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        --no-build)
            BUILD=false
            shift
            ;;
        --no-push)
            PUSH=false
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
    print_status "Starting publish process..."
    
    check_prerequisites
    build_image
    tag_image
    push_image
    verify_published_image
    show_published_info
    create_user_install_script
}

# Run main function
main 