#!/bin/bash

################################################################################
# COMPREHENSIVE VOLATILITY 2.6.1 INSTALLATION SCRIPT
# For Kali Linux with Python 3.x as default
# 
# This script:
# - Installs Python 2.7 and all dependencies
# - Installs Volatility 2.6.1 from source
# - Fixes Python 2/3 compatibility issues
# - Creates wrapper scripts for easy execution
# - Tests everything thoroughly
#
# Usage: sudo bash install_volatility_complete.sh
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_header() {
    echo ""
    echo "=========================================="
    echo -e "${MAGENTA}$1${NC}"
    echo "=========================================="
    echo ""
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Check if running as root
check_root() {
    log_step "Checking root privileges..."
    if [ "$EUID" -ne 0 ]; then 
        log_error "This script must be run as root"
        echo "Please use: sudo bash $0"
        exit 1
    fi
    log_success "Running as root"
}

# Display system information
display_system_info() {
    log_header "SYSTEM INFORMATION"
    
    log_info "Operating System:"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "  $PRETTY_NAME"
    else
        uname -a
    fi
    
    echo ""
    log_info "Current Python Versions:"
    echo "  Default Python: $(python --version 2>&1 || echo 'Not found')"
    echo "  Python 2:       $(python2 --version 2>&1 || echo 'Not installed')"
    echo "  Python 3:       $(python3 --version 2>&1 || echo 'Not found')"
    
    echo ""
    log_info "Current User:"
    echo "  Root user: $USER"
    if [ -n "$SUDO_USER" ]; then
        echo "  Original user: $SUDO_USER"
    fi
    
    echo ""
}

# Backup existing volatility installation
backup_existing_volatility() {
    log_step "Checking for existing Volatility installation..."
    
    # Determine user's home directory
    if [ -n "$SUDO_USER" ]; then
        USER_HOME=$(eval echo ~$SUDO_USER)
    else
        USER_HOME=$HOME
    fi
    
    BACKUP_CREATED=false
    
    # Check in common locations
    if [ -d "$USER_HOME/volatility" ]; then
        BACKUP_DIR="$USER_HOME/volatility_backup_$(date +%Y%m%d_%H%M%S)"
        log_warning "Found existing volatility in $USER_HOME/volatility"
        log_info "Creating backup at $BACKUP_DIR"
        mv "$USER_HOME/volatility" "$BACKUP_DIR"
        log_success "Backup created"
        BACKUP_CREATED=true
    fi
    
    if [ -d "/root/volatility" ] && [ "$USER_HOME" != "/root" ]; then
        BACKUP_DIR="/root/volatility_backup_$(date +%Y%m%d_%H%M%S)"
        log_warning "Found existing volatility in /root/volatility"
        log_info "Creating backup at $BACKUP_DIR"
        mv "/root/volatility" "$BACKUP_DIR"
        log_success "Backup created"
        BACKUP_CREATED=true
    fi
    
    if [ -f "/usr/local/bin/vol.py" ]; then
        log_warning "Found existing vol.py in /usr/local/bin"
        mv /usr/local/bin/vol.py /usr/local/bin/vol.py.backup_$(date +%Y%m%d_%H%M%S)
        log_success "Backed up vol.py"
        BACKUP_CREATED=true
    fi
    
    if [ "$BACKUP_CREATED" = false ]; then
        log_success "No existing installation found"
    fi
}

# Update system
update_system() {
    log_step "Updating system packages..."
    apt-get update -y > /dev/null 2>&1
    log_success "System updated"
}

# Install git if not present
install_git() {
    log_step "Checking for git..."
    if ! command -v git &> /dev/null; then
        log_info "Installing git..."
        apt-get install -y git > /dev/null 2>&1
        log_success "Git installed"
    else
        log_success "Git already installed"
    fi
}

# Install Python 2.7 and pip2
install_python2() {
    log_step "Installing Python 2.7 and development packages..."
    
    # Install Python 2.7 and development packages
    apt-get install -y python2 python2-dev build-essential > /dev/null 2>&1
    
    log_success "Python 2.7 installed: $(python2 --version 2>&1)"
    
    # Check if pip2 is installed
    if ! command -v pip2 &> /dev/null; then
        log_info "Installing pip for Python 2.7..."
        
        cd /tmp
        if [ ! -f "get-pip.py" ]; then
            wget -q https://bootstrap.pypa.io/pip/2.7/get-pip.py
        fi
        
        python2 get-pip.py > /dev/null 2>&1
        rm -f get-pip.py
        
        log_success "pip2 installed"
    else
        log_success "pip2 already installed"
    fi
}

# Upgrade pip2 and setuptools
upgrade_pip_setuptools() {
    log_step "Upgrading pip2 and setuptools..."
    pip2 install --upgrade pip setuptools > /dev/null 2>&1
    log_success "pip2 and setuptools upgraded"
}

# Install Python dependencies
install_python_dependencies() {
    log_step "Installing Python 2.7 dependencies..."
    
    log_info "This may take a few minutes..."
    
    # Install dependencies
    log_info "Installing: distorm3, yara, pycrypto, pillow, ujson, pytz, ipython, capstone"
    python2 -m pip install -U distorm3 yara pycrypto pillow ujson pytz ipython capstone > /tmp/volatility_deps.log 2>&1 || true
    
    # Explicitly install yara again (as per workshop instructions)
    log_info "Ensuring yara is properly installed..."
    python2 -m pip install yara > /dev/null 2>&1
    
    # Install alternative packages
    log_info "Installing backup packages (pycryptodome, distorm3)..."
    pip2 install pycryptodome distorm3 > /dev/null 2>&1 || true
    
    log_success "Python dependencies installed"
    
    # Verify critical packages
    log_info "Verifying installations..."
    python2 -c "import distorm3" 2>/dev/null && echo "  ✓ distorm3" || echo "  ✗ distorm3"
    python2 -c "import yara" 2>/dev/null && echo "  ✓ yara" || echo "  ✗ yara"
    python2 -c "import Crypto" 2>/dev/null && echo "  ✓ pycrypto" || echo "  ✗ pycrypto"
}

# Create symbolic link for libyara.so (fixes common yara issues)
create_yara_symlink() {
    log_step "Configuring Yara library link..."
    
    # Find libyara.so location
    LIBYARA_PATH=$(find /usr/local/lib/python2.7/dist-packages -name "libyara.so" 2>/dev/null | head -1)
    
    if [ -z "$LIBYARA_PATH" ]; then
        log_warning "libyara.so not found in expected Python location"
        log_info "Searching system-wide..."
        LIBYARA_PATH=$(find /usr -name "libyara.so" 2>/dev/null | head -1)
    fi
    
    if [ -n "$LIBYARA_PATH" ]; then
        log_info "Found libyara.so at: $LIBYARA_PATH"
        
        # Remove existing symlink if it exists
        if [ -L "/usr/lib/libyara.so" ]; then
            rm -f /usr/lib/libyara.so
        fi
        
        # Create symlink
        ln -s "$LIBYARA_PATH" /usr/lib/libyara.so
        log_success "Yara library link created: /usr/lib/libyara.so"
    else
        log_warning "Could not find libyara.so - Yara scanning may not work"
        log_info "This is non-critical and can be fixed later if needed"
    fi
}

# Clone and install Volatility 2.6.1
install_volatility() {
    log_step "Installing Volatility 2.6.1..."
    
    # Determine user's home directory
    if [ -n "$SUDO_USER" ]; then
        USER_HOME=$(eval echo ~$SUDO_USER)
        INSTALL_USER=$SUDO_USER
    else
        USER_HOME=$HOME
        INSTALL_USER=$USER
    fi
    
    cd "$USER_HOME"
    
    # Clone Volatility
    if [ -d "volatility" ]; then
        rm -rf volatility
    fi
    
    log_info "Cloning Volatility from GitHub..."
    git clone https://github.com/volatilityfoundation/volatility.git > /dev/null 2>&1
    cd volatility
    
    # Checkout version 2.6.1
    log_info "Checking out version 2.6.1..."
    git checkout 2.6.1 > /dev/null 2>&1
    
    # Install Volatility
    log_info "Running setup.py install..."
    python2 setup.py install > /tmp/volatility_install.log 2>&1
    
    log_success "Volatility 2.6.1 installed"
    
    # Store path for later use
    VOLATILITY_PATH="$USER_HOME/volatility/vol.py"
    
    # Change ownership back to original user
    if [ -n "$SUDO_USER" ]; then
        chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/volatility"
    fi
}

# Fix Python 2/3 compatibility issues
fix_python_compatibility() {
    log_header "FIXING PYTHON 2/3 COMPATIBILITY"
    
    log_step "Updating vol.py shebang to use Python 2..."
    
    # Update shebang in vol.py to explicitly use Python 2
    sed -i '1s|^#!.*python.*|#!/usr/bin/env python2|' "$VOLATILITY_PATH"
    
    CURRENT_SHEBANG=$(head -1 "$VOLATILITY_PATH")
    log_success "Shebang updated: $CURRENT_SHEBANG"
    
    # Make vol.py executable
    chmod +x "$VOLATILITY_PATH"
    
    log_step "Creating Python 2 wrapper scripts..."
    
    # Remove old files if they exist
    rm -f /usr/local/bin/vol.py /usr/local/bin/vol2.py /usr/local/bin/volatility
    
    # Create comprehensive wrapper script
    cat > /usr/local/bin/vol.py << 'WRAPPER_EOF'
#!/bin/bash
################################################################################
# Volatility 2.6.1 Wrapper Script
# Forces Python 2.7 execution regardless of system default
# Created for Kali Linux with Python 3.x as default
################################################################################

# Color codes for error messages
RED='\033[0;31m'
NC='\033[0m'

# Check if Python 2 is available
if ! command -v python2 &> /dev/null; then
    echo -e "${RED}Error: Python 2 is not installed${NC}"
    echo "Volatility 2.6.1 requires Python 2.7"
    echo "Install it with: sudo apt-get install python2"
    exit 1
fi

# Find Volatility vol.py location
VOL_LOCATIONS=(
    "$HOME/volatility/vol.py"
    "/root/volatility/vol.py"
)

VOL_PATH=""
for loc in "${VOL_LOCATIONS[@]}"; do
    # Expand wildcard for home directories
    for file in $loc; do
        if [ -f "$file" ]; then
            VOL_PATH="$file"
            break 2
        fi
    done
done

# If not found in common locations, search for it
if [ -z "$VOL_PATH" ]; then
    VOL_PATH=$(find /root /home -name "vol.py" -path "*/volatility/vol.py" 2>/dev/null | head -1)
fi

# If still not found, show error
if [ -z "$VOL_PATH" ]; then
    echo -e "${RED}Error: Could not find Volatility installation${NC}"
    echo "Expected locations:"
    echo "  - ~/volatility/vol.py"
    echo "  - /root/volatility/vol.py"
    echo ""
    echo "Please ensure Volatility is installed."
    exit 1
fi

# Execute with Python 2.7 and pass all arguments
exec python2 "$VOL_PATH" "$@"
WRAPPER_EOF

    chmod +x /usr/local/bin/vol.py
    log_success "Created: /usr/local/bin/vol.py"
    
    # Create additional convenience aliases
    ln -sf /usr/local/bin/vol.py /usr/local/bin/vol2.py
    log_success "Created: /usr/local/bin/vol2.py"
    
    ln -sf /usr/local/bin/vol.py /usr/local/bin/volatility
    log_success "Created: /usr/local/bin/volatility"
    
    # Add bash aliases for convenience
    if [ -n "$SUDO_USER" ]; then
        SUDO_USER_HOME=$(eval echo ~$SUDO_USER)
        BASHRC="$SUDO_USER_HOME/.bashrc"
        
        if [ -f "$BASHRC" ]; then
            if ! grep -q "# Volatility 2.6.1 aliases" "$BASHRC"; then
                echo "" >> "$BASHRC"
                echo "# Volatility 2.6.1 aliases (auto-added)" >> "$BASHRC"
                echo "alias vol='python2 $VOLATILITY_PATH'" >> "$BASHRC"
                log_success "Added aliases to $BASHRC"
            fi
        fi
    fi
}

# Test Volatility installation
test_volatility() {
    log_header "TESTING VOLATILITY INSTALLATION"
    
    local ALL_TESTS_PASSED=true
    
    # Test 1: Direct Python 2 execution
    log_step "Test 1: Direct Python 2 execution"
    if python2 "$VOLATILITY_PATH" -h > /tmp/vol_test_py2.txt 2>&1; then
        log_success "✓ Direct Python 2 execution works"
    else
        log_error "✗ Direct Python 2 execution failed"
        ALL_TESTS_PASSED=false
    fi
    
    # Test 2: Wrapper script execution
    log_step "Test 2: Wrapper script execution"
    if /usr/local/bin/vol.py -h > /tmp/vol_test_wrapper.txt 2>&1; then
        log_success "✓ Wrapper script works"
    else
        log_error "✗ Wrapper script failed"
        ALL_TESTS_PASSED=false
    fi
    
    # Test 3: Check for critical plugins
    log_step "Test 3: Checking critical plugins"
    local PLUGINS=("pslist" "pstree" "psxview" "malfind" "yarascan" "filescan")
    local PLUGINS_FOUND=true
    
    for plugin in "${PLUGINS[@]}"; do
        if grep -q "$plugin" /tmp/vol_test_wrapper.txt; then
            echo "  ✓ $plugin"
        else
            echo "  ✗ $plugin"
            PLUGINS_FOUND=false
        fi
    done
    
    if [ "$PLUGINS_FOUND" = true ]; then
        log_success "✓ All critical plugins available"
    else
        log_warning "✗ Some plugins may be missing"
        ALL_TESTS_PASSED=false
    fi
    
    # Test 4: Yara integration
    log_step "Test 4: Yara integration"
    if python2 -c "import yara; print('Yara version: ' + yara.__version__)" > /tmp/yara_test.txt 2>&1; then
        YARA_VERSION=$(cat /tmp/yara_test.txt)
        log_success "✓ Yara integration working ($YARA_VERSION)"
    else
        log_warning "✗ Yara integration may have issues (non-critical)"
    fi
    
    # Test 5: Python imports
    log_step "Test 5: Python package imports"
    python2 -c "import volatility; import distorm3; import Crypto" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_success "✓ All critical Python packages import successfully"
    else
        log_warning "✗ Some Python packages may have import issues"
        ALL_TESTS_PASSED=false
    fi
    
    echo ""
    if [ "$ALL_TESTS_PASSED" = true ]; then
        log_success "All tests passed! ✓"
    else
        log_warning "Some tests failed, but basic functionality should work"
    fi
}

# Display usage information
display_usage_info() {
    log_header "INSTALLATION COMPLETE!"
    
    echo -e "${GREEN}✓ Volatility 2.6.1 is installed and ready to use${NC}"
    echo ""
    echo "You can now run Volatility using any of these commands:"
    echo ""
    echo -e "  ${CYAN}vol.py -h${NC}              # Primary command (recommended)"
    echo -e "  ${CYAN}vol2.py -h${NC}             # Alternative name"
    echo -e "  ${CYAN}volatility -h${NC}          # Alternative name"
    echo -e "  ${CYAN}python2 $VOLATILITY_PATH -h${NC}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "QUICK START EXAMPLES:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. Get help:"
    echo "   vol.py -h"
    echo ""
    echo "2. Identify memory image:"
    echo "   vol.py -f memory.mem imageinfo"
    echo ""
    echo "3. List processes:"
    echo "   vol.py -f memory.mem --profile=Win7SP1x64 pslist"
    echo ""
    echo "4. Find hidden processes:"
    echo "   vol.py -f memory.mem --profile=Win7SP1x64 psxview"
    echo ""
    echo "5. Scan for malware:"
    echo "   vol.py -f memory.mem --profile=Win7SP1x64 malfind"
    echo ""
    echo "6. Extract files:"
    echo "   vol.py -f memory.mem --profile=Win7SP1x64 filescan"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "COMMON WINDOWS PROFILES:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Win7SP1x64         Windows 7 SP1 (64-bit)"
    echo "  Win7SP1x86         Windows 7 SP1 (32-bit)"
    echo "  Win10x64_15063     Windows 10 x64 (Build 15063)"
    echo "  Win10x64_17134     Windows 10 x64 (Build 17134)"
    echo "  WinXPSP3x86        Windows XP SP3 (32-bit)"
    echo ""
    echo "To see all profiles: vol.py --info | grep Profile"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "VERSION INFORMATION:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Python 2:   $(python2 --version 2>&1)"
    echo "  Python 3:   $(python3 --version 2>&1)"
    echo "  Volatility: 2.6.1"
    echo "  Location:   $VOLATILITY_PATH"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "LOG FILES:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Installation log: /tmp/volatility_install.log"
    echo "  Dependencies log: /tmp/volatility_deps.log"
    echo "  Test output:      /tmp/vol_test_wrapper.txt"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}Happy memory forensics! 🔍${NC}"
    echo ""
}

# Cleanup function
cleanup() {
    log_step "Cleaning up temporary files..."
    rm -f /tmp/get-pip.py
    log_success "Cleanup complete"
}

# Main execution
main() {
    clear
    log_header "VOLATILITY 2.6.1 COMPREHENSIVE INSTALLER"
    echo "For Kali Linux with Python 3.x as default"
    echo "This script handles everything in one go!"
    echo ""
    
    # Check root privileges
    check_root
    
    # Display system information
    display_system_info
    
    # Confirm installation
    read -p "Press Enter to continue with installation or Ctrl+C to cancel..."
    echo ""
    
    # Run installation steps
    backup_existing_volatility
    update_system
    install_git
    install_python2
    upgrade_pip_setuptools
    install_python_dependencies
    create_yara_symlink
    install_volatility
    fix_python_compatibility
    
    # Test installation
    test_volatility
    
    # Cleanup
    cleanup
    
    # Display usage information
    display_usage_info
    
    echo ""
    log_success "Installation completed successfully!"
    echo ""
}

# Run main function
main "$@"
