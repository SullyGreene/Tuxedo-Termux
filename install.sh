#!/data/data/com.termux/files/usr/bin/bash

# Define color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Variables ---
TUX_DIR="$HOME/.tuxedo"
TUX_SCRIPT_PATH="$PREFIX/bin/tux"
BASHRC_FILE="$HOME/.bashrc"
ALIASES="
# Tuxedo-Termux Aliases
alias tuxedo='tux'
alias tux-market='tux'
"

# --- Functions ---

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

# 1. Check Environment
check_environment() {
    log_info "Checking environment prerequisites..."

    if [ "$(id -u)" -eq 0 ]; then
        log_error "This installer must NOT be run as root (or with 'su')."
        log_error "Please run it as the normal Termux user."
        exit 1
    fi
    log_info "Installer running as non-root user. [OK]"

    if ! command -v su &> /dev/null; then
        log_warn "The 'su' binary was not found in your PATH."
        log_warn "Tuxedo-Termux requires a rooted device with 'su' accessible to Termux."
        log_warn "Installation will continue, but 'tux install' will fail."
    else
        log_info "'su' binary found in PATH. [OK]"
    fi
}

# 2. Install Dependencies
install_deps() {
    log_info "Updating package lists..."
    if ! pkg update -y; then
        log_warn "Failed to update package lists. This may cause issues if dependencies are not cached."
    fi

    log_info "Installing dependencies (git, jq, curl)..."
    # sha256sum is in 'coreutils'
    if ! pkg install -y git jq curl coreutils; then
        log_error "Failed to install dependencies. Please run 'pkg install git jq curl coreutils' manually and try again."
    fi
    log_info "Dependencies installed."
}

# 3. Create the main 'tux' executable
create_main_script() {
    log_info "Creating the 'tux' command at $TUX_SCRIPT_PATH..."
    
    mkdir -p "$TUX_DIR"

    # --- THIS IS THE FINAL 'tux' SCRIPT ---
    cat > "$TUX_SCRIPT_PATH" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# --- Tuxedo-Termux Main Script ---

# Configuration
TUX_DIR="$HOME/.tuxedo"
REPO_DIR="$TUX_DIR/repo"
TUX_TERMUX_REPO_URL="https://raw.githubusercontent.com/SullyGreene/Tuxedo-Termux/main/install.sh"
REPO_URL="https://github.com/SullyGreene/Tuxedo-Repo.git"
PACKAGE_DB="$REPO_DIR/packages.json"
# Temporary file for downloading installers
TMP_SCRIPT="/data/data/com.termux/files/usr/tmp/tux_installer.sh"

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
    echo "  search <keyword>  Search for a package by name or description"
    echo "  list            List all available packages"
    echo "  install <pkg>   Install a package (requires root)"
    echo "  self-update     Update the Tuxedo-Termux client to the latest version"
    echo "  help            Show this help message"
    echo ""
    echo "Aliases: tuxedo, tux-market"
}

# Check if the package database exists
check_db_exists() {
    if [ ! -f "$PACKAGE_DB" ]; then
        log_error "Package database not found at $PACKAGE_DB"
        log_info "Please run ${CYAN}tux update${NC} first to download the package list."
        exit 1
    fi
}

# Check for 'su' binary before trying to use it
check_root_prereq() {
    if ! command -v su &> /dev/null; then
        log_error "Root access ('su') is required for this command, but 'su' was not found."
        log_error "Please ensure your device is rooted and Termux has 'su' access."
        exit 1
    fi
}

# Verify the SHA256 checksum of a downloaded file
verify_checksum() {
    local FILE_PATH="$1"
    local EXPECTED_SUM="$2"
    
    if [ -z "$EXPECTED_SUM" ] || [ "$EXPECTED_SUM" == "null" ]; then
        log_warn "Package does not have a checksum. Proceeding with caution..."
        return
    fi
    
    log_info "Verifying installer integrity..."
    local ACTUAL_SUM
    ACTUAL_SUM=$(sha256sum "$FILE_PATH" | awk '{print $1}')
    
    if [ "$ACTUAL_SUM" != "$EXPECTED_SUM" ]; then
        log_error "CHECKSUM MISMATCH! ABORTING."
        log_error "Expected: $EXPECTED_SUM"
        log_error "Got:      $ACTUAL_SUM"
        log_warn "The downloaded file is corrupt or has been tampered with. Deleting."
        rm -f "$FILE_PATH"
        exit 1
    fi
    log_info "Checksum verified. [OK]"
}

# Install Termux dependencies for a package
install_pkg_deps() {
    local PKG_JSON="$1"
    # Get all dependencies, filter out 'null' or empty strings
    local DEPS
    DEPS=$(echo "$PKG_JSON" | jq -r '.dependencies[]? | select(length > 0)')
    
    if [ -z "$DEPS" ]; then
        log_info "Package has no Termux dependencies."
        return
    fi
    
    log_info "Checking Termux dependencies..."
    local ALL_INSTALLED=true
    local DEPS_TO_INSTALL=""
    
    for DEP in $DEPS; do
        # Check if package is installed and listed
        if ! pkg list-installed | grep -q "^$DEP/"; then
            log_warn "Dependency '${CYAN}$DEP${NC}' not found."
            DEPS_TO_INSTALL="$DEPS_TO_INSTALL $DEP"
            ALL_INSTALLED=false
        fi
    done
    
    if [ "$ALL_INSTALLED" = true ]; then
        log_info "All Termux dependencies are satisfied. [OK]"
    else
        log_info "Installing missing dependencies: $DEPS_TO_INSTALL"
        if ! pkg install -y $DEPS_TO_INSTALL; then
            log_error "Failed to install dependencies. Aborting."
            exit 1
        fi
    fi
}

# --- Main Logic ---

if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

COMMAND=$1
shift

# --- Command Handler ---
case "$COMMAND" in
    update)
        log_info "Updating package repository from $REPO_URL..."
        if [ -d "$REPO_DIR/.git" ]; then
            (cd "$REPO_DIR" && git pull origin main)
        else
            log_info "Cloning new repository..."
            rm -rf "$REPO_DIR"
            git clone "$REPO_URL" "$REPO_DIR"
        fi
        
        if [ $? -eq 0 ] && [ -f "$PACKAGE_DB" ]; then
            log_info "Package list updated successfully."
        else
            log_error "Failed to update package list or $PACKAGE_DB not found."
        fi
        ;;

    search)
        if [ -z "$1" ]; then
            log_error "Please provide a search keyword."
            echo "Usage: tux search <keyword>"
            exit 1
        fi
        local KEYWORD="$1"
        check_db_exists

        log_info "Searching for packages matching '${CYAN}$KEYWORD${NC}'..."
        
        local RESULTS
        RESULTS=$(jq -r --arg keyword "$KEYWORD" \
            '.[] | select(.name | test($keyword; "i") or .description | test($keyword; "i") or (.aliases[]? | test($keyword; "i"))) | [.name, .description] | @tsv' \
            "$PACKAGE_DB")
        
        if [ -z "$RESULTS" ]; then
            log_info "No packages found."
        else
            echo
            while IFS=$'\t' read -r name desc; do
                echo -e "  ${YELLOW}$name${NC}"
                echo -e "    $desc\n"
            done <<< "$RESULTS"
        fi
        ;;

    list)
        check_db_exists
        log_info "Listing all available packages..."
        
        local RESULTS
        RESULTS=$(jq -r '.[] | [.name, .description] | @tsv' "$PACKAGE_DB")

        if [ -z "$RESULTS" ]; then
            log_error "Package database is empty or corrupt."
        else
            echo
            while IFS=$'\t' read -r name desc; do
                echo -e "  ${YELLOW}$name${NC}"
                echo -e "    $desc\n"
            done <<< "$RESULTS"
        fi
        ;;

    install)
        # [FINAL] Install functionality
        local PKG_NAME="$1"
        if [ -z "$PKG_NAME" ]; then
            log_error "Please provide a package name to install."
            echo "Usage: tux install <package-name>"
            exit 1
        fi
        
        check_db_exists
        check_root_prereq
        
        log_info "Searching for package '${CYAN}$PKG_NAME${NC}'..."
        
        # Find the package by name or alias
        local PKG_JSON
        PKG_JSON=$(jq -c --arg name "$PKG_NAME" \
            '.[] | select(.name == $name or (.aliases[]? == $name))' \
            "$PACKAGE_DB")
            
        if [ -z "$PKG_JSON" ]; then
            log_error "Package '${CYAN}$PKG_NAME${NC}' not found in the repository."
            exit 1
        fi
        
        local REAL_NAME=$(echo "$PKG_JSON" | jq -r '.name')
        local INSTALL_URL=$(echo "$PKG_JSON" | jq -r '.install_script_url')
        local EXPECTED_SUM=$(echo "$PKG_JSON" | jq -r '.sha256_checksum')
        
        log_info "Found package: ${YELLOW}$REAL_NAME${NC}"
        
        # 1. Install Dependencies
        install_pkg_deps "$PKG_JSON"
        
        # 2. Download Installer
        log_info "Downloading installer from: $INSTALL_URL"
        rm -f "$TMP_SCRIPT" # Clean up any old script
        curl -sL "$INSTALL_URL" -o "$TMP_SCRIPT"
        
        if [ $? -ne 0 ] || [ ! -s "$TMP_SCRIPT" ]; then
            log_error "Failed to download installer script. Aborting."
            rm -f "$TMP_SCRIPT"
            exit 1
        fi
        
        # 3. Verify Checksum
        verify_checksum "$TMP_SCRIPT" "$EXPECTED_SUM"
        
        # 4. Execute with Root
        log_info "Checksum OK. Granting root access to installer..."
        log_warn "Watch your superuser prompt to grant permission."
        chmod +x "$TMP_SCRIPT"
        
        # Execute script with 'su'
        su -c "$TMP_SCRIPT"
        local INSTALL_STATUS=$?
        
        # 5. Cleanup
        log_info "Cleaning up temporary files..."
        rm -f "$TMP_SCRIPT"
        
        if [ $INSTALL_STATUS -eq 0 ]; then
            log_info "${GREEN}Installation of $REAL_NAME completed successfully.${NC}"
        else
            log_error "The installer for $REAL_NAME finished with an error (code: $INSTALL_STATUS)."
        fi
        ;;

    self-update)
        log_info "Checking for updates to Tuxedo-Termux client..."
        local TMP_SELF_UPDATE_SCRIPT="$TUX_DIR/tux_self_update_installer.sh" # Use TUX_DIR for temp files

        log_info "Downloading latest installer from $TUX_TERMUX_REPO_URL..."
        # Use -f to fail silently on 404/etc. and check exit code
        if ! curl -sL -f "$TUX_TERMUX_REPO_URL" -o "$TMP_SELF_UPDATE_SCRIPT"; then
            log_error "Failed to download the latest Tuxedo-Termux installer. Check network connectivity."
            rm -f "$TMP_SELF_UPDATE_SCRIPT"
            exit 1
        fi

        if [ ! -s "$TMP_SELF_UPDATE_SCRIPT" ]; then
            log_error "Downloaded installer is empty or corrupt. Aborting self-update."
            rm -f "$TMP_SELF_UPDATE_SCRIPT"
            exit 1
        fi

        log_info "Executing the latest installer to update 'tux'..."
        # The install.sh script is designed to be idempotent and will update the tux script
        # It will also re-add aliases if they are missing, etc.
        # Run it with bash, not sh, as it uses bash features.
        if ! bash "$TMP_SELF_UPDATE_SCRIPT"; then
            log_error "Self-update failed during installer execution."
            rm -f "$TMP_SELF_UPDATE_SCRIPT"
            exit 1
        fi

        log_info "Tuxedo-Termux client updated successfully!"
        log_warn "You may need to restart Termux or run 'source ~/.bashrc' if aliases were updated."
        rm -f "$TMP_SELF_UPDATE_SCRIPT"
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
    # --- END OF 'tux' SCRIPT ---

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
    check_environment
    install_deps
    create_main_script
    add_aliases
    log_info "${GREEN}Installation complete!${NC}"
    log_warn "Please restart Termux or run 'source ~/.bashrc' to use the 'tux' command."
}

# Run the installer
main
