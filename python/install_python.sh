#!/bin/bash
#
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                                                                              ┃
# ┃   ██████╗ ██╗   ██╗████████╗██╗  ██╗ ██████╗ ███╗   ██╗                     ┃
# ┃   ██╔══██╗╚██╗ ██╔╝╚══██╔══╝██║  ██║██╔═══██╗████╗  ██║                     ┃
# ┃   ██████╔╝ ╚████╔╝    ██║   ███████║██║   ██║██╔██╗ ██║                     ┃
# ┃   ██╔═══╝   ╚██╔╝     ██║   ██╔══██║██║   ██║██║╚██╗██║                     ┃
# ┃   ██║        ██║      ██║   ██║  ██║╚██████╔╝██║ ╚████║                     ┃
# ┃   ╚═╝        ╚═╝      ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝                     ┃
# ┃                                                                              ┃
# ┃   Cross-Platform Python Installation Script                                  ┃
# ┃   Version: 1.0.0                                                             ┃
# ┃   Author: crushoverride007                                                   ┃
# ┃   Repository: https://github.com/Crushoverride007/scripts                    ┃
# ┃                                                                              ┃
# ┃   This script automatically installs Python with pip on Linux, macOS,        ┃
# ┃   and Windows systems, and configures the environment variables.             ┃
# ┃                                                                              ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
#
# Cross-platform Python installation script
# Installs Python with pip and sets up environment variables
# Works on Linux, macOS, and Windows (via Git Bash or WSL)
#

# Set up colors for output (will be ignored on Windows CMD/PowerShell)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Initialize variables to store versions
PYTHON_VERSION="Unknown"
PIP_VERSION="Unknown"

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
    print_message $CYAN "┃   Cross-Platform Python Installation Script                                  ┃"
    print_message $CYAN "┃   Version: 1.0.0                                                             ┃"
    print_message $CYAN "┃   Author: crushoverride007                                                   ┃"
    print_message $CYAN "┃   Repository: https://github.com/Crushoverride007/scripts                    ┃"
    print_message $CYAN "┃                                                                              ┃"
    print_message $CYAN "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    echo ""
}

# Print the completion banner with version information
print_completion_banner() {
    # Get the latest Python and pip versions
    if [ "$OS" = "Windows" ]; then
        # For Windows, try to get versions via PowerShell
        if command -v powershell.exe &> /dev/null; then
            PYTHON_VERSION=$(powershell.exe -Command "python --version" 2>/dev/null || echo "Unknown")
            PIP_VERSION=$(powershell.exe -Command "pip --version" 2>/dev/null || echo "Unknown")
            # Clean up the output
            PYTHON_VERSION=$(echo "$PYTHON_VERSION" | tr -d '\r')
            PIP_VERSION=$(echo "$PIP_VERSION" | tr -d '\r')
        fi
    else
        # For Linux/macOS
        if command -v python3 &> /dev/null; then
            PYTHON_VERSION=$(python3 --version 2>&1)
        elif command -v python &> /dev/null; then
            PYTHON_VERSION=$(python --version 2>&1)
        fi
        
        if command -v pip3 &> /dev/null; then
            PIP_VERSION=$(pip3 --version 2>&1 | awk '{print $1 " " $2}')
        elif command -v pip &> /dev/null; then
            PIP_VERSION=$(pip --version 2>&1 | awk '{print $1 " " $2}')
        fi
    fi
    
    # Format versions for display
    PYTHON_VERSION=$(echo "$PYTHON_VERSION" | sed 's/Python //')
    
    echo ""
    print_message $CYAN "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    print_message $CYAN "┃                                                                              ┃"
    print_message $CYAN "┃   Installation Summary                                                       ┃"
    print_message $CYAN "┃   -------------------                                                        ┃"
    print_message $CYAN "┃   System: $OS on $ARCH architecture                                          "
    print_message $CYAN "┃   Python Version: $PYTHON_VERSION                                            "
    print_message $CYAN "┃   Pip Version: $PIP_VERSION                                                  "
    print_message $CYAN "┃                                                                              ┃"
    print_message $CYAN "┃   All done! Python is ready to use on your system.                           ┃"
    print_message $CYAN "┃   Script created by crushoverride007                                         ┃"
    print_message $CYAN "┃   https://github.com/Crushoverride007/scripts                                ┃"
    print_message $CYAN "┃                                                                              ┃"
    print_message $CYAN "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
}

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

# Check if running in Windows
if [[ "$OS" == *"MINGW"* ]] || [[ "$OS" == *"MSYS"* ]] || [[ "$OS" == *"CYGWIN"* ]]; then
    OS="Windows"
    # Check if PowerShell is available
    if command -v powershell.exe &> /dev/null; then
        WINDOWS_ARCH=$(powershell.exe -Command "(Get-CimInstance Win32_OperatingSystem).OSArchitecture")
        if [[ "$WINDOWS_ARCH" == *"64"* ]]; then
            if [[ "$WINDOWS_ARCH" == *"ARM"* ]]; then
                ARCH="arm64"
            else
                ARCH="x86_64"
            fi
        else
            ARCH="x86"
        fi
    fi
fi

# Display welcome banner
print_welcome_banner

print_message $BLUE "=== This script will install Python 3 with pip and set up environment variables ==="
print_message $YELLOW "Detected system: $OS on $ARCH architecture"

# Function for Linux installation
install_on_linux() {
    # Check if script is run with root privileges
    if [ "$EUID" -ne 0 ]; then
        print_message $RED "Please run this script with sudo or as root on Linux."
        exit 1
    fi

    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$NAME
        VER=$VERSION_ID
        print_message $YELLOW "Detected Linux distribution: $DISTRO $VER"
    else
        print_message $RED "Cannot detect Linux distribution. Proceeding with generic installation."
        DISTRO="Unknown"
    fi

    # Check if apt is available
    if command -v apt &> /dev/null; then
        # Debian/Ubuntu based
        print_message $YELLOW "Using apt package manager..."
        
        # Update package lists
        print_message $YELLOW "Updating package lists..."
        apt update

        # Install Python3 and pip
        print_message $YELLOW "Installing Python 3 and pip for $ARCH architecture..."
        apt install -y python3 python3-pip python3-venv
        
    elif command -v dnf &> /dev/null; then
        # Fedora/RHEL based
        print_message $YELLOW "Using dnf package manager..."
        
        # Update package lists
        print_message $YELLOW "Updating package lists..."
        dnf check-update
        
        # Install Python3 and pip
        print_message $YELLOW "Installing Python 3 and pip for $ARCH architecture..."
        dnf install -y python3 python3-pip python3-devel
        
    elif command -v pacman &> /dev/null; then
        # Arch based
        print_message $YELLOW "Using pacman package manager..."
        
        # Update package lists
        print_message $YELLOW "Updating package lists..."
        pacman -Sy
        
        # Install Python3 and pip
        print_message $YELLOW "Installing Python 3 and pip for $ARCH architecture..."
        pacman -S --noconfirm python python-pip
        
    else
        print_message $RED "Unsupported package manager. Please install Python manually."
        exit 1
    fi

    # Create symbolic links for python and pip (if they don't exist)
    print_message $YELLOW "Creating symbolic links..."
    if ! command -v python &> /dev/null; then
        ln -sf $(which python3) /usr/bin/python
        print_message $GREEN "Created symbolic link for python"
    fi

    if ! command -v pip &> /dev/null; then
        ln -sf $(which pip3) /usr/bin/pip
        print_message $GREEN "Created symbolic link for pip"
    fi

    # Ensure pip binaries are in PATH for all users
    print_message $YELLOW "Configuring environment variables..."

    # Create a file in /etc/profile.d/ to add Python paths
    cat > /etc/profile.d/python_path.sh << 'EOF'
# Add Python and pip to PATH
export PATH="$PATH:/usr/bin:/usr/local/bin:$HOME/.local/bin"
EOF

    chmod +x /etc/profile.d/python_path.sh

    # Add to current user's .bashrc if it exists
    if [ "$SUDO_USER" ] && [ -f "/home/$SUDO_USER/.bashrc" ]; then
        if ! grep -q "PATH.*\.local\/bin" "/home/$SUDO_USER/.bashrc"; then
            print_message $YELLOW "Adding Python paths to user's .bashrc..."
            echo 'export PATH="$PATH:$HOME/.local/bin"' >> "/home/$SUDO_USER/.bashrc"
        fi
    fi

    # Get installed versions
    PYTHON_VERSION=$(python3 --version 2>&1)
    PIP_VERSION=$(pip3 --version 2>&1 | awk '{print $1 " " $2}')

    print_message $GREEN "=== Python installation complete on Linux! ==="
    print_message $GREEN "=== You may need to log out and back in or run 'source /etc/profile.d/python_path.sh' to apply PATH changes ==="
}

# Function for macOS installation
install_on_macos() {
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_message $YELLOW "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for the current session
        if [ "$ARCH" = "arm64" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        print_message $GREEN "Homebrew is already installed."
    fi

    # Update Homebrew
    print_message $YELLOW "Updating Homebrew..."
    brew update

    # Install Python
    if brew list python3 &>/dev/null; then
        print_message $GREEN "Python 3 is already installed. Upgrading if needed..."
        brew upgrade python3
    else
        print_message $YELLOW "Installing Python 3..."
        brew install python3
    fi

    # Verify Python and pip are installed
    PYTHON_VERSION=$(python3 --version 2>&1)
    PIP_VERSION=$(pip3 --version 2>&1 | awk '{print $1 " " $2}')
    print_message $GREEN "Python installed: $PYTHON_VERSION"
    print_message $GREEN "Pip installed: $PIP_VERSION"

    # Set up environment variables
    print_message $YELLOW "Configuring environment variables..."
    
    # Determine shell configuration file
    SHELL_CONFIG=""
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_CONFIG" ]; then
        # Add Python paths if not already present
        if ! grep -q "PATH.*python" "$SHELL_CONFIG"; then
            print_message $YELLOW "Adding Python paths to $SHELL_CONFIG..."
            if [ "$ARCH" = "arm64" ]; then
                echo 'export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"' >> "$SHELL_CONFIG"
                echo 'export PATH="$PATH:$HOME/Library/Python/3.*/bin"' >> "$SHELL_CONFIG"
            else
                echo 'export PATH="/usr/local/bin:/usr/local/sbin:$PATH"' >> "$SHELL_CONFIG"
                echo 'export PATH="$PATH:$HOME/Library/Python/3.*/bin"' >> "$SHELL_CONFIG"
            fi
        fi
    else
        print_message $RED "Could not find shell configuration file. Please manually add Python to your PATH."
    fi

    print_message $GREEN "=== Python installation complete on macOS! ==="
    print_message $GREEN "=== You may need to restart your terminal or run 'source $SHELL_CONFIG' to apply PATH changes ==="
}

# Function for Windows installation
install_on_windows() {
    print_message $YELLOW "Installing Python on Windows..."
    
    # Check if we're in WSL
    if grep -q Microsoft /proc/version 2>/dev/null; then
        print_message $YELLOW "Detected Windows Subsystem for Linux (WSL)."
        print_message $YELLOW "Installing for Linux environment instead..."
        install_on_linux
        return
    fi
    
    # Check if we're in a proper bash environment (Git Bash, etc.)
    if ! command -v powershell.exe &> /dev/null; then
        print_message $RED "This script requires PowerShell to install Python on Windows."
        print_message $RED "Please run this script from Git Bash or install PowerShell."
        exit 1
    fi
    
    # Create a temporary PowerShell script
    print_message $YELLOW "Creating temporary PowerShell installation script..."
    
    PS_SCRIPT=$(mktemp --suffix=.ps1)
    
    cat > "$PS_SCRIPT" << 'EOF'
# PowerShell script to install Python on Windows
# Created by crushoverride007

Write-Host "Starting Python installation on Windows..." -ForegroundColor Yellow

# Check if Python is already installed
$pythonInstalled = $false
try {
    $pythonVersion = (python --version 2>&1)
    if ($pythonVersion -match "Python 3") {
        Write-Host "Python is already installed: $pythonVersion" -ForegroundColor Green
        $pythonInstalled = $true
    }
} catch {
    # Python not installed or not in PATH
}

if (-not $pythonInstalled) {
    # Determine architecture
    $arch = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
    
    # Download Python installer
    $tempDir = [System.IO.Path]::GetTempPath()
    $pythonInstallerPath = Join-Path $tempDir "python_installer.exe"
    
    Write-Host "Downloading Python installer for $arch..." -ForegroundColor Yellow
    
    # Determine correct URL based on architecture
    if ($arch -like "*ARM64*") {
        $url = "https://www.python.org/ftp/python/3.11.4/python-3.11.4-arm64.exe"
    } else {
        $url = "https://www.python.org/ftp/python/3.11.4/python-3.11.4-amd64.exe"
    }
    
    # Download the installer
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $pythonInstallerPath
    
    # Install Python
    Write-Host "Installing Python..." -ForegroundColor Yellow
    Start-Process -FilePath $pythonInstallerPath -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_test=0" -Wait
    
    # Clean up
    Remove-Item $pythonInstallerPath -Force
    
    Write-Host "Python installation completed." -ForegroundColor Green
} else {
    Write-Host "Using existing Python installation." -ForegroundColor Green
}

# Verify pip is installed
try {
    $pipVersion = (pip --version 2>&1)
    Write-Host "Pip is installed: $pipVersion" -ForegroundColor Green
} catch {
    Write-Host "Installing pip..." -ForegroundColor Yellow
    # Download get-pip.py
    $getPipPath = Join-Path ([System.IO.Path]::GetTempPath()) "get-pip.py"
    Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile $getPipPath
    
    # Run get-pip.py
    python $getPipPath
    
    # Clean up
    Remove-Item $getPipPath -Force
}

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Output installed versions to a temp file for the bash script to read
$pythonVersion = (python --version 2>&1)
$pipVersion = (pip --version 2>&1)
$tempFile = Join-Path $env:TEMP "python_versions.txt"
"Python: $pythonVersion" | Out-File -FilePath $tempFile
"Pip: $pipVersion" | Out-File -FilePath $tempFile -Append

Write-Host "Python environment is ready to use!" -ForegroundColor Green
EOF
    
    # Run the PowerShell script with elevated privileges
    print_message $YELLOW "Running PowerShell installation script with admin privileges..."
    powershell.exe -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"$PS_SCRIPT\"' -Verb RunAs -Wait"
    
    # Try to get the installed versions from PowerShell
    TEMP_FILE=$(powershell.exe -Command "[System.IO.Path]::GetTempPath() + 'python_versions.txt'" | tr -d '\r')
    if [ -f "$TEMP_FILE" ]; then
        # Read versions from the temp file
        PYTHON_LINE=$(grep "Python:" "$TEMP_FILE" | head -1)
        PIP_LINE=$(grep "Pip:" "$TEMP_FILE" | head -1)
        
        # Extract versions
        PYTHON_VERSION=$(echo "$PYTHON_LINE" | sed 's/Python: Python //')
        PIP_VERSION=$(echo "$PIP_LINE" | sed 's/Pip: pip //' | awk '{print $1}')
    else
        # Fallback to direct PowerShell commands
        PYTHON_VERSION=$(powershell.exe -Command "python --version" 2>/dev/null | sed 's/Python //' | tr -d '\r' || echo "Unknown")
        PIP_VERSION=$(powershell.exe -Command "pip --version" 2>/dev/null | awk '{print $1 " " $2}' | tr -d '\r' || echo "Unknown")
    fi
    
    # Clean up
    rm "$PS_SCRIPT"
    
    print_message $GREEN "=== Python installation on Windows complete! ==="
    print_message $GREEN "=== You may need to restart your terminal to apply PATH changes ==="
    print_message $GREEN "=== If Python commands are not recognized, try opening a new Command Prompt or PowerShell window ==="
}

# Main installation logic based on OS
if [ "$OS" = "Darwin" ]; then
    print_message $YELLOW "Installing for macOS..."
    install_on_macos
elif [ "$OS" = "Linux" ]; then
    print_message $YELLOW "Installing for Linux..."
    install_on_linux
elif [ "$OS" = "Windows" ]; then
    print_message $YELLOW "Installing for Windows..."
    install_on_windows
else
    print_message $RED "Unsupported operating system: $OS"
    exit 1
fi

# Verify installation (for Linux and macOS)
if [ "$OS" != "Windows" ]; then
    print_message $YELLOW "Verifying Python installation..."
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1)
        PIP_VERSION=$(pip3 --version 2>&1 | awk '{print $1 " " $2}')
        print_message $GREEN "Python installed: $PYTHON_VERSION"
        print_message $GREEN "Pip: $PIP_VERSION"
    else
        print_message $RED "Python installation verification failed. Please check for errors."
    fi

    # Install some common Python packages (optional)
    print_message $YELLOW "Would you like to install some common Python packages? (requests, numpy, pandas) [y/N]"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message $YELLOW "Installing common Python packages for $ARCH architecture..."
        pip3 install requests numpy pandas
        print_message $GREEN "Common packages installed!"
    fi
fi

# Display completion banner with version information
print_completion_banner
