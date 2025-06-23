#!/bin/bash

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

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

# Get the current user (the one who ran sudo)
REAL_USER=${SUDO_USER:-$USER}

print_status "=== Secure User Setup Script ==="
echo

# Prompt for username
while true; do
    read -p "Enter the username for the new user: " NEW_USER
    if [[ "$NEW_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] && [ ${#NEW_USER} -le 32 ]; then
        break
    else
        print_error "Invalid username. Use only lowercase letters, numbers, underscore, and hyphen. Max 32 characters."
    fi
done

# Check if user already exists
if id "$NEW_USER" &>/dev/null; then
    print_error "User '$NEW_USER' already exists!"
    exit 1
fi

print_status "Creating user: $NEW_USER"

# Create the user
adduser --gecos "" "$NEW_USER"

if [ $? -ne 0 ]; then
    print_error "Failed to create user"
    exit 1
fi

print_success "User '$NEW_USER' created successfully"

# Add user to sudo group
print_status "Adding user to sudo group..."
usermod -aG sudo "$NEW_USER"

if [ $? -eq 0 ]; then
    print_success "User added to sudo group"
else
    print_error "Failed to add user to sudo group"
    exit 1
fi

# Set up SSH directory and permissions
print_status "Setting up SSH directory..."
USER_HOME="/home/$NEW_USER"
SSH_DIR="$USER_HOME/.ssh"

# Create .ssh directory
sudo -u "$NEW_USER" mkdir -p "$SSH_DIR"
sudo -u "$NEW_USER" chmod 700 "$SSH_DIR"

# Check if root has authorized_keys to copy
ROOT_AUTH_KEYS="/root/.ssh/authorized_keys"
USER_AUTH_KEYS="$SSH_DIR/authorized_keys"

if [ -f "$ROOT_AUTH_KEYS" ]; then
    print_status "Copying SSH keys from root user..."
    cp "$ROOT_AUTH_KEYS" "$USER_AUTH_KEYS"
    chown "$NEW_USER:$NEW_USER" "$USER_AUTH_KEYS"
    chmod 600 "$USER_AUTH_KEYS"
    print_success "SSH keys copied successfully"
else
    print_warning "No SSH keys found for root user"
    print_status "Creating empty authorized_keys file..."
    sudo -u "$NEW_USER" touch "$USER_AUTH_KEYS"
    sudo -u "$NEW_USER" chmod 600 "$USER_AUTH_KEYS"
    print_warning "You'll need to add your SSH public key manually to: $USER_AUTH_KEYS"
fi

# Test sudo access
print_status "Testing sudo access for $NEW_USER..."
if sudo -u "$NEW_USER" sudo -n true 2>/dev/null; then
    print_success "Sudo access configured correctly"
else
    print_status "Sudo access will require password (this is normal)"
fi

# SSH Hardening Option
echo
print_status "SSH Security Hardening"
echo "This will:"
echo "  • Disable root SSH login"
echo "  • Disable password authentication"
echo "  • Enable public key authentication only"
echo "  • Restrict SSH access to $NEW_USER only"
echo
print_warning "IMPORTANT: Make sure SSH key authentication works before proceeding!"
print_warning "Test in another terminal: ssh $NEW_USER@$(hostname -I | awk '{print $1}')"
echo

while true; do
    read -p "Do you want to apply SSH hardening now? (y/n): " HARDEN_SSH
    case $HARDEN_SSH in
        [Yy]* ) 
            print_status "Applying SSH hardening..."
            break
            ;;
        [Nn]* ) 
            print_warning "Skipping SSH hardening. You can apply it manually later."
            SKIP_HARDENING=true
            break
            ;;
        * ) 
            echo "Please answer yes (y) or no (n)."
            ;;
    esac
done

if [ "$SKIP_HARDENING" != true ]; then
    # Configure SSH security
    print_status "Configuring SSH security..."
    SSH_CONFIG="/etc/ssh/sshd_config"
    BACKUP_CONFIG="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"

    # Backup original config
    cp "$SSH_CONFIG" "$BACKUP_CONFIG"
    print_status "SSH config backed up to: $BACKUP_CONFIG"

    # Update SSH configuration
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
    sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSH_CONFIG"
    sed -i 's/^#*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' "$SSH_CONFIG"

    # Add AllowUsers directive if it doesn't exist
    if ! grep -q "^AllowUsers" "$SSH_CONFIG"; then
        echo "AllowUsers $NEW_USER" >> "$SSH_CONFIG"
        print_status "Added AllowUsers directive for $NEW_USER"
    fi

    print_success "SSH security configured"

    # Restart SSH service
    print_status "Restarting SSH service..."
    systemctl restart sshd

    if [ $? -eq 0 ]; then
        print_success "SSH service restarted successfully"
        SSH_HARDENED=true
    else
        print_error "Failed to restart SSH service"
        print_warning "Restoring backup configuration..."
        cp "$BACKUP_CONFIG" "$SSH_CONFIG"
        systemctl restart sshd
        exit 1
    fi
fi

# Final instructions
echo
print_success "=== Setup Complete! ==="
echo
print_status "Summary:"
echo "  • User '$NEW_USER' created with sudo privileges"
echo "  • SSH directory configured with proper permissions"
if [ -f "$ROOT_AUTH_KEYS" ]; then
    echo "  • SSH keys copied from root user"
else
    echo "  • SSH keys need to be added manually"
fi

if [ "$SSH_HARDENED" = true ]; then
    echo "  • SSH hardening applied (root login disabled, password auth disabled)"
else
    echo "  • SSH hardening skipped"
fi

echo
print_status "Next steps:"
echo "  1. Test SSH connection: ssh $NEW_USER@$(hostname -I | awk '{print $1}')"
if [ ! -f "$ROOT_AUTH_KEYS" ]; then
    echo "  2. Add your SSH public key to: $USER_AUTH_KEYS"
fi
echo "  3. Update your local SSH config to use the new user"

if [ "$SKIP_HARDENING" = true ]; then
    echo "  4. Apply SSH hardening manually when ready:"
    echo "     sudo nano /etc/ssh/sshd_config"
    echo "     # Set: PermitRootLogin no"
    echo "     # Set: PasswordAuthentication no"
    echo "     sudo systemctl restart sshd"
fi

echo
if [ "$SSH_HARDENED" = true ]; then
    print_warning "IMPORTANT: SSH is now hardened. Only key-based authentication allowed!"
else
    print_warning "NOTE: SSH hardening was skipped. Server is still accessible via password."
fi
