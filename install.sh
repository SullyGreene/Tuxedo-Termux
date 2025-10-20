#!/data/data/com.termux/files/usr/bin/bash

# Define color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Variables ---
# Main installation directory for Tuxedo files (e.g., the repo clone)
TUX_DIR="$HOME/.tuxedo"
# Path to the main executable script
TUX_SCRIPT_PATH="$PREFIX/bin/tux"
# Alias definitions
BASHRC_FILE="$HOME/.bashrc"
ALIASES="
# Tuxedo-Termux Aliases
alias tuxedo='tux'
alias tux-market='tux'
"

# --- Functions ---

# Function to print a formatted message
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 1. Check Environment (NEW FUNCTION)
check_environment() {
    log_info "Checking environment prerequisites..."

    # Check 1: Installer must NOT be run as root.
    if [ "$(id -u)" -eq 0 ]; then
        log_error "This installer must NOT be run as root (or with 'su')."
        log_error "Please run it as the normal Termux user (e.g., 'u0_a123')."
        log_error "The 'tux' command will call 'su' itself when it needs root privileges."
        exit 1
    fi
    log_info "Installer running as non-root user. [OK]"

    # Check 2: 'su' binary (the root prerequisite) must be available.
    if ! command -v su &> /dev/null; then
        log_warn "The 'su' binary was not found in your PATH."
        log_warn "Tuxedo-Termux requires a rooted device with 'su' accessible to Termux."
        log_warn "Installation will continue, but 'tux install' will fail until 'su' is available."
    else
        log_info "'su' binary found in PATH. [OK]"
    fi
}

# 2. Install Dependencies
install_deps() {
    log_info "Updating package lists..."
    pkg update -y > /dev/null 2>&1
    log_info "Installing dependencies (git, jq, curl)..."
    pkg install -y git jq curl > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log_error "Failed to install dependencies. Please run 'pkg install git jq curl' manually and try again."
    fi
    log_info "Dependencies installed."
}

# 3. Create the main 'tux' executable
create_main_script() {
    log_info "Creating the 'tux' command at $TUX_SCRIPT_PATH..."
    
    # Create the main directory
    mkdir -p "$TUX_DIR"

    # Here we will write the main 'tux' script.
    # This skeleton is unchanged from our previous step.
    cat > "$TUX_SCRIPT_PATH" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# --- Tuxedo-Termux Main Script ---

# Configuration
TUX_DIR="$HOME/.tuxedo"
REPO_DIR="$TUX_DIR/repo"
REPO_URL="https://github.com/SullyGreene/Tuxedo-Repo.git"
PACKAGE_DB="$REPO_DIR/packages.json"

# Color Codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Helper Functions ---

log_info() {
    echo -e "${GREEN}[TUX]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[TUX]${NC} $1"
}

log_error() {
    echo -e "${RED}[TUX]${NC} $1"
}

show_help() {
    echo "Tuxedo-Termux: The Rooted Android Package Manager"
    echo ""
    echo "Usage: tux <command> [options]"
    echo ""
    echo "Commands:"
    echo "  update          Sync the local package list with the remote repository"
    echo "  search <keyword>  Search for a package"
    echo "  list            List all available packages"
    echo "  install <pkg>   Install a package (requires root)"
    echo "  help            Show this help message"
    echo ""
    echo "Aliases: tuxedo, tux-market"
}

# --- Main Logic ---

# Ensure at least one argument is given
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Get the command
COMMAND=$1
shift # Remove the command from the arguments list

# --- Command Handler ---
case "$COMMAND" in
    update)
        log_info "Updating package repository..."
        if [ -d "$REPO_DIR" ]; then
            (cd "$REPO_DIR" && git pull origin main)
        else
            git clone "$REPO_URL" "$REPO_DIR"
        fi
        
        if [ $? -eq 0 ]; then
            log_info "Package list updated successfully."
        else
            log_error "Failed to update package list."
        fi
        ;;

    search)
        log_warn "Search command is not yet implemented."
        ;;

    list)
        log_warn "List command is not yet implemented."
        ;;

    install)
        log_warn "Install command is not yet implemented."
        ;;

    help|--help|-h)
        show_help
        ;;

    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
EOF

    # Make the script executable
    chmod +x "$TUX_SCRIPT_PATH"
    if [ $? -ne 0 ]; then
        log_error "Failed to make 'tux' script executable. Check permissions."
    fi
    log_info "'tux' command is now available."
}

# 4. Add Aliases
add_aliases() {
    log_info "Adding aliases (tuxedo, tux-market) to $BASHRC_FILE..."
    if ! grep -q "# Tuxedo-Termux Aliases" "$BASHRC_FILE"; then
        echo "$ALIASES" >> "$BASHRC_FILE"
        log_info "Aliases added."
    else
        log_info "Aliases already exist."
    fi
}

# --- Main Execution ---
main() {
    log_info "Starting Tuxedo-Termux installation..."
    # This is the new execution order
    check_environment
    install_deps
    create_main_script
    add_aliases
    log_info "${GREEN}Installation complete!${NC}"
    log_warn "Please restart Termux or run 'source ~/.bashrc' to use the 'tux' command."
}

# Run the installer
main
