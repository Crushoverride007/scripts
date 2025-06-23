#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${CYAN}$1${NC}"
}

# Variables to track what was done
SCRIPT_START_TIME=$(date)
USER_CREATED=false
SUDO_ADDED=false
SSH_DIR_CREATED=false
SSH_KEYS_COPIED=false
SSH_KEYS_MANUAL=false
SSH_HARDENED=false
SERVER_IP=$(hostname -I | awk '{print $1}')

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

# Get the current user (the one who ran sudo)
REAL_USER=${SUDO_USER:-$USER}

print_header "=== Secure User Setup Script ==="
echo

# Fix input handling for piped execution
exec < /dev/tty

# Prompt for username with better validation
while true; do
    echo -n "Enter the username for the new user: "
    read NEW_USER
    
    # Check if empty
    if [ -z "$NEW_USER" ]; then
        print_error "Username cannot be empty."
        continue
    fi
    
    # Check username format
    if [[ "$NEW_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] && [ ${#NEW_USER} -le 32 ]; then
        break
    else
        print_error "Invalid username. Requirements:"
        echo "  - Start with lowercase letter or underscore"
        echo "  - Use only lowercase letters, numbers, underscore, and hyphen"
        echo "  - Maximum 32 characters"
        echo "  - Examples: john, user_1, test-user"
    fi
done

# Check if user already exists
if id "$NEW_USER" &>/dev/null; then
    print_error "User '$NEW_USER' already exists!"
    print_status "Would you like to:"
    echo "1. Remove existing user and recreate"
    echo "2. Exit and choose different username"
    echo -n "Choose option (1/2): "
    read CHOICE
    
    case $CHOICE in
        1)
            print_warning "Removing existing user '$NEW_USER'..."
            userdel -r "$NEW_USER" 2>/dev/null
            if [ $? -eq 0 ]; then
                print_success "User '$NEW_USER' removed successfully"
            else
                print_warning "User removal had some issues, continuing anyway..."
            fi
            ;;
        2)
            print_status "Exiting. Please run the script again with a different username."
            exit 0
            ;;
        *)
            print_error "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Generate a random password
TEMP_PASSWORD=$(openssl rand -base64 12)

print_status "Creating user: $NEW_USER"

# Create the user with non-interactive method
useradd -m -s /bin/bash "$NEW_USER"

if [ $? -ne 0 ]; then
    print_error "Failed to create user"
    exit 1
fi

# Set the temporary password
echo "$NEW_USER:$TEMP_PASSWORD" | chpasswd

if [ $? -ne 0 ]; then
    print_error "Failed to set password"
    exit 1
fi

print_success "User '$NEW_USER' created successfully"
USER_CREATED=true

# Add user to sudo group
print_status "Adding user to sudo group..."
usermod -aG sudo "$NEW_USER"

if [ $? -eq 0 ]; then
    print_success "User added to sudo group"
    SUDO_ADDED=true
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
SSH_DIR_CREATED=true

# Check if root has authorized_keys to copy
ROOT_AUTH_KEYS="/root/.ssh/authorized_keys"
USER_AUTH_KEYS="$SSH_DIR/authorized_keys"

if [ -f "$ROOT_AUTH_KEYS" ]; then
    print_status "Copying SSH keys from root user..."
    cp "$ROOT_AUTH_KEYS" "$USER_AUTH_KEYS"
    chown "$NEW_USER:$NEW_USER" "$USER_AUTH_KEYS"
    chmod 600 "$USER_AUTH_KEYS"
    print_success "SSH keys copied successfully"
    SSH_KEYS_COPIED=true
else
    print_warning "No SSH keys found for root user"
    print_status "Creating empty authorized_keys file..."
    sudo -u "$NEW_USER" touch "$USER_AUTH_KEYS"
    sudo -u "$NEW_USER" chmod 600 "$USER_AUTH_KEYS"
    print_warning "You'll need to add your SSH public key manually to: $USER_AUTH_KEYS"
    SSH_KEYS_MANUAL=true
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
print_warning "Test in another terminal: ssh $NEW_USER@$SERVER_IP"
echo

while true; do
    echo -n "Do you want to apply SSH hardening now? (y/n): "
    read HARDEN_SSH
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

SCRIPT_END_TIME=$(date)

# Enhanced Summary Section
echo
echo "========================================================================"
print_header "                    SETUP COMPLETE SUMMARY"
echo "========================================================================"
echo
print_header "📋 EXECUTION DETAILS"
echo "Started:  $SCRIPT_START_TIME"
echo "Finished: $SCRIPT_END_TIME"
echo "Server:   $SERVER_IP"
echo "User:     $NEW_USER"
echo "Password: $TEMP_PASSWORD"
echo

print_header "✅ COMPLETED TASKS"
if [ "$USER_CREATED" = true ]; then
    echo "  ✓ User '$NEW_USER' created with home directory"
    echo "  ✓ Temporary password set: $TEMP_PASSWORD"
fi
if [ "$SUDO_ADDED" = true ]; then
    echo "  ✓ User added to sudo group (admin privileges)"
fi
if [ "$SSH_DIR_CREATED" = true ]; then
    echo "  ✓ SSH directory created with proper permissions (700)"
fi
if [ "$SSH_KEYS_COPIED" = true ]; then
    echo "  ✓ SSH keys copied from root user"
    echo "  ✓ SSH key authentication ready"
fi
if [ "$SSH_HARDENED" = true ]; then
    echo "  ✓ SSH hardening applied:"
    echo "    - Root login disabled"
    echo "    - Password authentication disabled"
    echo "    - Public key authentication enforced"
    echo "    - Access restricted to '$NEW_USER' only"
fi
echo

if [ "$SSH_KEYS_MANUAL" = true ] || [ "$SKIP_HARDENING" = true ]; then
    print_header "⚠️  PENDING ACTIONS"
    if [ "$SSH_KEYS_MANUAL" = true ]; then
        echo "  ! Add your SSH public key to: $USER_AUTH_KEYS"
    fi
    if [ "$SKIP_HARDENING" = true ]; then
        echo "  ! SSH hardening not applied (server still accepts passwords)"
    fi
    echo
fi

print_header "🔧 CONNECTION DETAILS"
echo "SSH Command:    ssh $NEW_USER@$SERVER_IP"
echo "User Home:      $USER_HOME"
echo "SSH Keys:       $USER_AUTH_KEYS"
echo "Temp Password:  $TEMP_PASSWORD"
if [ "$SSH_HARDENED" = true ]; then
    echo "Auth Method:    SSH Key Only"
else
    echo "Auth Method:    SSH Key + Password"
fi
echo

print_header "📝 NEXT STEPS"
echo "1. Update your local SSH config (~/.ssh/config):"
echo "   Host $SERVER_IP"
echo "       HostName $SERVER_IP"
echo "       User $NEW_USER"
echo "       IdentityFile ~/.ssh/your_private_key"
echo "       IdentitiesOnly yes"
echo

if [ "$SSH_KEYS_MANUAL" = true ]; then
    echo "2. Add your SSH public key to the server:"
    echo "   echo 'your-public-key-here' >> $USER_AUTH_KEYS"
    echo
fi

echo "3. Change the temporary password:"
echo "   ssh $NEW_USER@$SERVER_IP"
echo "   passwd"
echo

if [ "$SKIP_HARDENING" = true ]; then
    echo "4. Apply SSH hardening when ready:"
    echo "   sudo nano /etc/ssh/sshd_config"
    echo "   # Set: PermitRootLogin no"
    echo "   # Set: PasswordAuthentication no"
    echo "   sudo systemctl restart sshd"
    echo
fi

echo "5. Test the connection:"
echo "   ssh $NEW_USER@$SERVER_IP"
echo

print_header "🛡️  SECURITY STATUS"
if [ "$SSH_HARDENED" = true ]; then
    print_success "HIGH - SSH hardening applied, key-based auth only"
else
    print_warning "MEDIUM - SSH hardening pending, password auth still enabled"
fi
echo

print_header "🔑 IMPORTANT SECURITY NOTE"
print_warning "Temporary password: $TEMP_PASSWORD"
print_warning "Change this password immediately after first login!"
echo

print_header "📞 SUPPORT"
echo "If you encounter issues:"
echo "• Check SSH key permissions: ls -la ~/.ssh/"
echo "• Verify server connectivity: ping $SERVER_IP"
echo "• Check SSH logs: sudo tail -f /var/log/auth.log"
echo
echo "========================================================================"
print_success "Setup completed successfully! Server is ready for use."
echo "========================================================================"
