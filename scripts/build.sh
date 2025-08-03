#!/bin/bash

# Build script for Vagrant Podman container

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
BUILD_ARGS=""
DEV_MODE=false

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

Build the Vagrant Podman container image.

OPTIONS:
    -t, --tag TAG           Tag for the image (default: latest)
    -n, --name NAME         Image name (default: vagrant-libvirt)
    -d, --dev               Build with development tools
    -h, --help              Show this help message

EXAMPLES:
    $0                      # Build with default settings
    $0 -t v1.0.0           # Build with specific tag
    $0 --dev               # Build with development tools
    $0 -n my-vagrant -t dev # Build with custom name and tag

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
    
    # Check if entrypoint.sh exists
    if [ ! -f "entrypoint.sh" ]; then
        print_error "entrypoint.sh not found in current directory."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to build the image
build_image() {
    print_status "Building Podman image: ${IMAGE_NAME}:${TAG}"
    
    # Build arguments
    BUILD_CMD="podman build"
    
    if [ "$DEV_MODE" = true ]; then
        print_status "Building in development mode"
        BUILD_CMD="$BUILD_CMD --build-arg DEV_MODE=true"
    fi
    
    BUILD_CMD="$BUILD_CMD -t ${IMAGE_NAME}:${TAG} ."
    
    print_status "Executing: $BUILD_CMD"
    
    if eval "$BUILD_CMD"; then
        print_success "Image built successfully: ${IMAGE_NAME}:${TAG}"
    else
        print_error "Failed to build image"
        exit 1
    fi
}

# Function to verify the build
verify_build() {
    print_status "Verifying build..."
    
    # Check if image exists
    if ! podman image exists "${IMAGE_NAME}:${TAG}"; then
        print_error "Image ${IMAGE_NAME}:${TAG} not found after build"
        exit 1
    fi
    
    # Test basic functionality
    print_status "Testing container functionality..."
    
    if podman run --rm "${IMAGE_NAME}:${TAG}" vagrant --version >/dev/null 2>&1; then
        print_success "Container test passed"
    else
        print_warning "Container test failed - this might be expected in some environments"
    fi
    
    # Show image info
    print_status "Image information:"
    podman image inspect "${IMAGE_NAME}:${TAG}" --format "{{.RepoTags}} {{.Size}} {{.Created}}"
}

# Function to show next steps
show_next_steps() {
    cat << EOF

${GREEN}Build completed successfully!${NC}

Next steps:
1. Install on local machine: ./scripts/install.sh
2. Publish to registry: ./scripts/publish.sh
3. Test the container: podman run --rm ${IMAGE_NAME}:${TAG} vagrant --version

For more information, see README.md

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -d|--dev)
            DEV_MODE=true
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
    print_status "Starting build process..."
    
    check_prerequisites
    build_image
    verify_build
    show_next_steps
}

# Run main function
main 