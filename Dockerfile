# Use Ubuntu 22.04 as base image for better compatibility
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV VAGRANT_HOME=/.vagrant.d
ENV LIBVIRT_DEFAULT_URI=qemu:///session

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install HashiCorp GPG key and repository
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

# Install Vagrant and development tools
RUN apt-get update && apt-get install -y \
    vagrant \
    build-essential \
    pkg-config \
    libvirt-dev \
    libvirt-daemon-system \
    qemu-kvm \
    qemu-utils \
    libguestfs-tools \
    ruby-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Ruby gems for plugin dependencies
RUN gem install \
    ffi \
    nokogiri \
    ruby-libvirt \
    fog-libvirt

# Remove system-installed vagrant-libvirt to avoid version conflicts
RUN apt-get remove -y vagrant-libvirt || true

# Install Vagrant plugins
RUN vagrant plugin install \
    vagrant-libvirt \
    vagrant-ignition \
    vagrant-env

# Create non-root user for better security
RUN useradd -m -s /bin/bash vagrant-user
RUN mkdir -p /.vagrant.d && chown -R vagrant-user:vagrant-user /.vagrant.d

# Set up entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER vagrant-user

# Set working directory
WORKDIR /workspace

# Expose libvirt socket directory
VOLUME ["/var/run/libvirt"]

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["vagrant", "--help"] 