#!/bin/bash

# Terraform Installation Script
# Author: crushoverride007
# Repository: https://github.com/Crushoverride007/scripts
# Created: June 25, 2025
# Description: Installs Terraform on various platforms and architectures

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║              Terraform Installation Script                 ║"
echo "║                                                            ║"
echo "║                Author: crushoverride007                    ║"
echo "║     https://github.com/Crushoverride007/scripts           ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root or with sudo privileges${NC}"
  exit 1
fi

# Function to get system information
get_system_info() {
  echo -e "${CYAN}=== System Information ===${NC}"
  
  # Get OS information
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VERSION=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VERSION=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VERSION=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    OS="Debian"
    VERSION=$(cat /etc/debian_version)
  elif [ -f /etc/redhat-release ]; then
    OS=$(cat /etc/redhat-release | cut -d ' ' -f 1)
    VERSION=$(cat /etc/redhat-release | sed 's/.*release \([0-9]\).*/\1/')
  elif [ "$(uname)" == "Darwin" ]; then
    OS="macOS"
    VERSION=$(sw_vers -productVersion)
  else
    OS="Unknown"
    VERSION="Unknown"
  fi
  
  # Get architecture
  ARCH=$(uname -m)
  case $ARCH in
    x86_64)
      ARCH="amd64"
      ;;
    aarch64|arm64)
      ARCH="arm64"
      ;;
    armv7l)
      ARCH="arm"
      ;;
  esac
  
  # Get IP address
  if [ "$(uname)" == "Darwin" ]; then
    IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
  else
    IP=$(hostname -I | awk '{print $1}')
  fi
  
  # Display information
  echo -e "${YELLOW}Operating System:${NC} $OS $VERSION"
  echo -e "${YELLOW}Architecture:${NC} $ARCH"
  echo -e "${YELLOW}IP Address:${NC} $IP"
  echo -e "${YELLOW}Hostname:${NC} $(hostname)"
  echo ""
}

# Function to check if Terraform is already installed
check_terraform() {
  if command -v terraform &>/dev/null; then
    TERRAFORM_VERSION=$(terraform version | head -n1 | cut -d 'v' -f2)
    echo -e "${GREEN}Terraform is already installed (version $TERRAFORM_VERSION)${NC}"
    return 0
  else
    echo -e "${YELLOW}Terraform is not installed. Proceeding with installation...${NC}"
    return 1
  fi
}

# Function to install Terraform on Debian/Ubuntu
install_terraform_debian() {
  echo -e "${CYAN}Installing Terraform on Debian/Ubuntu...${NC}"
  apt-get update
  apt-get install -y gnupg software-properties-common curl
  
  # Import HashiCorp GPG key
  curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  
  # Add HashiCorp repository
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
  
  # Install Terraform
  apt-get update && apt-get install -y terraform
}

# Function to install Terraform on RHEL/CentOS/Fedora
install_terraform_rhel() {
  echo -e "${CYAN}Installing Terraform on RHEL/CentOS/Fedora...${NC}"
  yum install -y yum-utils
  yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
  yum install -y terraform
}

# Function to install Terraform on macOS
install_terraform_macos() {
  echo -e "${CYAN}Installing Terraform on macOS...${NC}"
  if ! command -v brew &>/dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew tap hashicorp/tap
  brew install hashicorp/tap/terraform
}

# Function to install Terraform on Alpine
install_terraform_alpine() {
  echo -e "${CYAN}Installing Terraform on Alpine...${NC}"
  apk add --update terraform
}

# Function to install Terraform manually (for unsupported platforms)
install_terraform_manually() {
  echo -e "${CYAN}Installing Terraform manually...${NC}"
  
  # Determine latest version
  LATEST_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
  
  # Determine OS
  if [ "$(uname)" == "Darwin" ]; then
    OS="darwin"
  elif [ "$(uname)" == "Linux" ]; then
    OS="linux"
  else
    echo -e "${RED}Unsupported operating system: $(uname)${NC}"
    exit 1
  fi
  
  # Download and install
  TF_URL="https://releases.hashicorp.com/terraform/${LATEST_VERSION}/terraform_${LATEST_VERSION}_${OS}_${ARCH}.zip"
  echo -e "${YELLOW}Downloading Terraform from: ${TF_URL}${NC}"
  
  curl -s -o /tmp/terraform.zip ${TF_URL}
  unzip -o /tmp/terraform.zip -d /tmp
  mv /tmp/terraform /usr/local/bin/
  chmod +x /usr/local/bin/terraform
  rm /tmp/terraform.zip
}

# Main installation function
install_terraform() {
  # Get system information
  get_system_info
  
  # Check if Terraform is already installed
  check_terraform && return 0
  
  # Install based on OS
  case $OS in
    *Ubuntu*|*Debian*|*Mint*)
      install_terraform_debian
      ;;
    *Red*|*CentOS*|*Fedora*|*Amazon*)
      install_terraform_rhel
      ;;
    *macOS*)
      install_terraform_macos
      ;;
    *Alpine*)
      install_terraform_alpine
      ;;
    *)
      echo -e "${YELLOW}Unsupported OS detected. Attempting manual installation...${NC}"
      install_terraform_manually
      ;;
  esac
  
  # Verify installation
  if command -v terraform &>/dev/null; then
    TERRAFORM_VERSION=$(terraform version | head -n1 | cut -d 'v' -f2)
    echo -e "${GREEN}Terraform $TERRAFORM_VERSION has been successfully installed!${NC}"
    terraform -version
  else
    echo -e "${RED}Terraform installation failed.${NC}"
    exit 1
  fi
}

# Run the installation
install_terraform

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${CYAN}Thank you for using crushoverride007's Terraform installation script${NC}"
echo -e "${CYAN}Visit https://github.com/Crushoverride007/scripts for more useful scripts${NC}"
