#!/bin/bash
#
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                                                                              ┃
# ┃   ██████╗  ██████╗  ██████╗██╗  ██╗███████╗██████╗                          ┃
# ┃   ██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗                         ┃
# ┃   ██║  ██║██║   ██║██║     █████╔╝ █████╗  ██████╔╝                         ┃
# ┃   ██║  ██║██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗                         ┃
# ┃   ██████╔╝╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║                         ┃
# ┃   ╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝                         ┃
# ┃                                                                              ┃
# ┃   Docker Installation Script                                                 ┃
# ┃   Version: 1.0.0                                                             ┃
# ┃   Author: crushoverride007                                                   ┃
# ┃   Repository: https://github.com/Crushoverride007/scripts                    ┃
# ┃                                                                              ┃
# ┃   This script automatically installs Docker and Docker Compose               ┃
# ┃   on Ubuntu/Debian systems.                                                  ┃
# ┃                                                                              ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
#

# Set up colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Initialize variables to store versions
DOCKER_VERSION="Unknown"
DOCKER_COMPOSE_VERSION="Unknown"
CONTAINERD_VERSION="Unknown"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print the welcome banner
print_welcome_banner() {
    echo ""
    print_message $CYAN "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    print_message $CYAN "┃                                                                              ┃"
    print_message $CYAN "┃   Docker Installation Script                                                 ┃"
    print_message $CYAN "┃   Version: 1.0.0                                                             ┃"
    print_message $CYAN "┃   Author: crushoverride007                                                   ┃"
    print_message $CYAN "┃   Repository: https://github.com/Crushoverride007/scripts                    ┃"
    print_message $CYAN "┃                                                                              ┃"
    print_message $CYAN "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    echo ""
}

# Print the completion banner with version information
print_completion_banner() {
    echo ""
    print_message $CYAN "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    print_message $CYAN "┃                                                                              ┃"
    print_message $CYAN "┃   Installation Summary                                                       ┃"
    print_message $CYAN "┃   -------------------                                                        ┃"
    print_message $CYAN "┃   System: $(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om)                                            "
    print_message $CYAN "┃   Architecture: $(dpkg --print-architecture)                                                    "
    print_message $CYAN "┃   Docker Version: $DOCKER_VERSION                                            "
    print_message $CYAN "┃   Docker Compose Version: $DOCKER_COMPOSE_VERSION                            "
    print_message $CYAN "┃   Containerd Version: $CONTAINERD_VERSION                                    "
    print_message $CYAN "┃                                                                              ┃"
    print_message $CYAN "┃   All done! Docker is ready to use on your system.                           ┃"
    print_message $CYAN "┃   Script created by crushoverride007                                         ┃"
    print_message $CYAN "┃   https://github.com/Crushoverride007/scripts                                ┃"
    print_message $CYAN "┃                                                                              ┃"
    print_message $CYAN "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
}

# Set exit on error
set -e  # Exit immediately if a command fails

# Display welcome banner
print_welcome_banner

print_message $BLUE "=== This script will install Docker and Docker Compose on your system ==="

# Check if script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    print_message $RED "Please run this script with sudo or as root."
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    CODENAME=$VERSION_CODENAME
    print_message $YELLOW "Detected OS: $OS $VER ($CODENAME)"
else
    print_message $RED "Cannot detect OS. This script is designed for Ubuntu/Debian."
    exit 1
fi

# Check if the OS is Ubuntu or Debian
if [[ "$OS" != *"Ubuntu"* ]] && [[ "$OS" != *"Debian"* ]]; then
    print_message $YELLOW "Warning: This script is designed for Ubuntu/Debian. Your OS is $OS."
    print_message $YELLOW "The script may not work correctly. Do you want to continue? (y/n)"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message $RED "Installation aborted."
        exit 1
    fi
fi

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    EXISTING_DOCKER_VERSION=$(docker --version 2>/dev/null | cut -d ' ' -f3 | tr -d ',')
    print_message $YELLOW "Docker is already installed (version $EXISTING_DOCKER_VERSION)."
    print_message $YELLOW "Would you like to reinstall/update Docker? (y/n)"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message $GREEN "Skipping Docker installation."
        
        # Still capture version information for the summary
        DOCKER_VERSION=$EXISTING_DOCKER_VERSION
        DOCKER_COMPOSE_VERSION=$(docker compose version 2>/dev/null | cut -d ' ' -f4 | tr -d ',' || echo "Not installed")
        CONTAINERD_VERSION=$(containerd --version 2>/dev/null | cut -d ' ' -f3 || echo "Not installed")
        
        # Check if user is in docker group
        if [ "$SUDO_USER" ]; then
            if groups $SUDO_USER | grep -q '\bdocker\b'; then
                print_message $GREEN "User $SUDO_USER is already in the docker group."
            else
                print_message $YELLOW "User $SUDO_USER is not in the docker group. Adding now..."
                usermod -aG docker $SUDO_USER
                print_message $GREEN "User $SUDO_USER added to the docker group. You may need to log out and back in for this to take effect."
            fi
        fi
        
        # Skip to completion banner
        print_completion_banner
        print_message $YELLOW "Note: If you want to use Docker as a non-root user, log out and log back in for the group membership to take effect."
        exit 0
    else
        print_message $YELLOW "Proceeding with Docker reinstallation/update..."
    fi
fi

# Update package index
print_message $YELLOW "Updating package index..."
apt-get update

# Install prerequisites
print_message $YELLOW "Installing prerequisites..."
apt-get install -y ca-certificates curl gnupg lsb-release

# Create keyrings directory if it doesn't exist
print_message $YELLOW "Setting up Docker repository..."
install -m 0755 -d /etc/apt/keyrings

# Download Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository to apt sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
print_message $YELLOW "Updating package index with Docker repository..."
apt-get update

# Install Docker packages
print_message $YELLOW "Installing Docker packages..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group if not running as root user
if [ "$SUDO_USER" ]; then
    print_message $YELLOW "Adding user $SUDO_USER to the docker group..."
    usermod -aG docker $SUDO_USER
    print_message $GREEN "User $SUDO_USER added to the docker group. You may need to log out and back in for this to take effect."
fi

# Get installed versions
print_message $YELLOW "Verifying installation..."
DOCKER_VERSION=$(docker --version 2>/dev/null | cut -d ' ' -f3 | tr -d ',')
DOCKER_COMPOSE_VERSION=$(docker compose version 2>/dev/null | cut -d ' ' -f4 | tr -d ',')
CONTAINERD_VERSION=$(containerd --version 2>/dev/null | cut -d ' ' -f3)

# Display versions
print_message $GREEN "Docker version: $DOCKER_VERSION"
print_message $GREEN "Docker Compose version: $DOCKER_COMPOSE_VERSION"
print_message $GREEN "Containerd version: $CONTAINERD_VERSION"

# Test Docker installation
print_message $YELLOW "Testing Docker installation..."
docker run --rm hello-world

print_message $GREEN "Docker installation completed successfully!"

# Display completion banner with version information
print_completion_banner

print_message $YELLOW "Note: If you want to use Docker as a non-root user, log out and log back in for the group membership to take effect."
