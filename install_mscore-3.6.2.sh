#!/bin/bash
# MuseScore 3.6.2 Headless Mode Installer
# This script installs MuseScore 3.6.2 in headless mode on an Ubuntu server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APPIMAGE_URL="https://github.com/musescore/MuseScore/releases/download/v3.6.2/MuseScore-3.6.2.548021370-x86_64.AppImage"
APPIMAGE_FILE="MuseScore-3.6.2.548021370-x86_64.AppImage"
INSTALL_DIR="$HOME/mscore-3.6.2"
WRAPPER_SCRIPT="./wrapper_command.sh"

echo "=================================================="
echo "MuseScore 3.6.2 Headless Mode Installer"
echo "=================================================="
echo ""

# Function to print colored messages
print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}!${NC} $1"
}

print_info() {
  echo -e "${BLUE}→${NC} $1"
}

print_step() {
  echo -e "${BLUE}[Step $1/$2]${NC} $3"
}

# Error handler
error_exit() {
  print_error "$1"
  echo ""
  print_error "Installation failed!"
  exit 1
}

# Check if running on Ubuntu
check_system() {
  print_info "Checking system requirements..."
  
  if [ ! -f /etc/os-release ]; then
    error_exit "Cannot detect operating system"
  fi
  
  . /etc/os-release
  
  if [ "$ID" != "ubuntu" ]; then
    print_warning "This script is designed for Ubuntu"
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      print_info "Installation cancelled"
      exit 0
    fi
  else
    print_success "Detected: $PRETTY_NAME"
  fi
  echo ""
}

# Check if MuseScore is already installed
check_existing_installation() {
  print_info "Checking for existing installation..."
  
  local found=0
  
  if [ -d "$INSTALL_DIR" ]; then
    print_warning "Found existing directory: $INSTALL_DIR"
    found=1
  fi
  
  if [ -f "/usr/local/bin/musescore" ]; then
    print_warning "Found existing command: /usr/local/bin/musescore"
    found=1
  fi
  
  if [ $found -eq 1 ]; then
    echo ""
    read -p "Do you want to overwrite the existing installation? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      print_info "Installation cancelled"
      exit 0
    fi
    print_info "Will overwrite existing installation"
  else
    print_success "No existing installation found"
  fi
  echo ""
}

# Install dependencies
install_dependencies() {
  print_step 1 5 "Installing dependencies"
  print_info "Updating package list..."
  
  if ! sudo apt-get update > /dev/null 2>&1; then
    error_exit "Failed to update package list"
  fi
  print_success "Package list updated"
  
  print_info "Installing required packages..."
  
  DEPENDENCIES=(
    "xvfb"
    "libnss3-dev"
    "libegl1-mesa-dev"
    "libglu1-mesa-dev"
    "freeglut3-dev"
    "mesa-common-dev"
    "libjack-jackd2-dev"
    "libxss1"
    "libgconf-2-4"
    "libxtst6"
    "libxrandr2"
    "libasound2-dev"
  )
  
  if sudo apt-get install -y "${DEPENDENCIES[@]}" > /dev/null 2>&1; then
    print_success "All dependencies installed successfully"
  else
    error_exit "Failed to install dependencies"
  fi
  echo ""
}

# Download AppImage
download_appimage() {
  print_step 2 5 "Downloading MuseScore 3.6.2 AppImage"
  
  if [ -f "$APPIMAGE_FILE" ]; then
    print_warning "AppImage file already exists"
    read -p "Do you want to re-download it? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rm -f "$APPIMAGE_FILE"
    else
      print_info "Using existing AppImage file"
      echo ""
      return 0
    fi
  fi
  
  print_info "Downloading from GitHub..."
  print_info "This may take a few minutes..."
  
  if wget -O "$APPIMAGE_FILE" "$APPIMAGE_URL" 2>&1 | grep --line-buffered "%" | sed -u -e "s,\.,,g" | awk '{printf("\r  Progress: %s", $2)}'; then
    echo ""
    print_success "Download completed"
    
    local size=$(du -sh "$APPIMAGE_FILE" 2>/dev/null | cut -f1)
    print_info "File size: $size"
  else
    error_exit "Failed to download AppImage"
  fi
  echo ""
}

# Extract AppImage
extract_appimage() {
  print_step 3 5 "Extracting AppImage"
  
  print_info "Making AppImage executable..."
  chmod +x "$APPIMAGE_FILE" || error_exit "Failed to make AppImage executable"
  print_success "AppImage is now executable"
  
  print_info "Extracting AppImage (this may take a moment)..."
  if ./"$APPIMAGE_FILE" --appimage-extract > /dev/null 2>&1; then
    print_success "AppImage extracted successfully"
  else
    error_exit "Failed to extract AppImage"
  fi
  
  print_info "Moving extracted files to $INSTALL_DIR..."
  
  # Remove existing directory if it exists
  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
  fi
  
  if mv ./squashfs-root "$INSTALL_DIR"; then
    print_success "Files moved to $INSTALL_DIR"
  else
    error_exit "Failed to move extracted files"
  fi
  
  print_info "Cleaning up..."
  rm -f "$APPIMAGE_FILE"
  print_success "Cleanup completed"
  
  local size=$(du -sh "$INSTALL_DIR" 2>/dev/null | cut -f1)
  print_info "Installation size: $size"
  echo ""
}

# Test the installation
test_installation() {
  print_step 4 5 "Testing MuseScore installation"
  
  print_info "Running MuseScore with xvfb-run..."
  
  if xvfb-run -a "$INSTALL_DIR/AppRun" -v > /dev/null 2>&1; then
    print_success "MuseScore runs successfully"
  else
    error_exit "MuseScore test failed"
  fi
  echo ""
}

# Install wrapper commands
install_wrapper() {
  print_step 5 5 "Installing wrapper commands"
  
  if [ ! -f "$WRAPPER_SCRIPT" ]; then
    error_exit "Wrapper script not found: $WRAPPER_SCRIPT"
  fi
  
  print_info "Making wrapper script executable..."
  chmod +x "$WRAPPER_SCRIPT" || error_exit "Failed to make wrapper script executable"
  print_success "Wrapper script is now executable"
  
  print_info "Copying wrapper to /usr/local/bin/musescore..."
  if sudo cp "$WRAPPER_SCRIPT" /usr/local/bin/musescore; then
    print_success "Copied to /usr/local/bin/musescore"
  else
    error_exit "Failed to copy wrapper script"
  fi
  
  print_info "Creating symlink for 'mscore' command..."
  sudo rm -f /usr/local/bin/mscore 2>/dev/null
  if sudo ln -s /usr/local/bin/musescore /usr/local/bin/mscore; then
    print_success "Created symlink: /usr/local/bin/mscore"
  else
    error_exit "Failed to create symlink"
  fi
  echo ""
}

# Verify installation
verify_installation() {
  print_info "Verifying installation..."
  
  local issues=0
  
  # Check directory
  if [ -d "$INSTALL_DIR" ]; then
    print_success "Installation directory exists: $INSTALL_DIR"
  else
    print_error "Installation directory not found: $INSTALL_DIR"
    issues=$((issues + 1))
  fi
  
  # Check wrapper commands
  if [ -f "/usr/local/bin/musescore" ]; then
    print_success "Command available: musescore"
  else
    print_error "Command not found: musescore"
    issues=$((issues + 1))
  fi
  
  if [ -L "/usr/local/bin/mscore" ]; then
    print_success "Command available: mscore"
  else
    print_error "Command not found: mscore"
    issues=$((issues + 1))
  fi
  
  # Test command execution
  if command -v musescore &> /dev/null; then
    print_success "musescore command is in PATH"
  else
    print_error "musescore command not in PATH"
    issues=$((issues + 1))
  fi
  
  if [ $issues -eq 0 ]; then
    print_success "All verification checks passed"
  else
    print_warning "Found $issues issue(s) during verification"
  fi
  echo ""
}

# Print usage information
print_usage_info() {
  echo "=================================================="
  print_success "Installation completed successfully!"
  echo "=================================================="
  echo ""
  echo "You can now use MuseScore in headless mode with:"
  echo ""
  echo "  musescore -S style.mss -r 300 -o output.png input.musicxml"
  echo ""
  echo "Or using the short command:"
  echo ""
  echo "  mscore -S style.mss -r 300 -o output.png input.musicxml"
  echo ""
  echo "For help, run:"
  echo ""
  echo "  musescore --help"
  echo ""
}

# Validate sudo access
validate_sudo() {
  print_info "This script requires sudo privileges for some operations"
  print_info "Please enter your password to continue..."
  
  if ! sudo -v; then
    error_exit "Failed to obtain sudo privileges"
  fi
  
  print_success "Sudo privileges validated"
  echo ""
  
  # Keep sudo alive in the background
  # This refreshes the sudo timestamp every 60 seconds
  ( while true; do sudo -v; sleep 60; done ) &
  SUDO_REFRESH_PID=$!
  
  # Kill the background process when script exits
  trap "kill $SUDO_REFRESH_PID 2>/dev/null" EXIT
}

# Main installation process
main() {
  check_system
  validate_sudo
  check_existing_installation
  install_dependencies
  download_appimage
  extract_appimage
  test_installation
  install_wrapper
  verify_installation
  print_usage_info
}

# Run main function
main