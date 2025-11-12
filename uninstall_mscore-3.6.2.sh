#!/bin/bash
# This script removes 
# This script uninstalls MuseScore 3.6.2 in headless mode on an Ubuntu server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MUSESCORE_DIR="$HOME/mscore-3.6.2"
WRAPPER_PATHS=("/usr/bin/musescore" "/usr/bin/mscore" "/usr/bin/mscore3" )

echo "=================================================="
echo "MuseScore 3.6.2 Headless Mode Uninstaller"
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
  echo -e "${NC}→${NC} $1"
}

# Remove wrapper commands
remove_wrappers() {
  print_info "Removing wrapper commands..."
  
  local removed=0
  for wrapper in "${WRAPPER_PATHS[@]}"; do
    if [ -f "$wrapper" ] || [ -L "$wrapper" ]; then
      if sudo rm -f "$wrapper" 2>/dev/null; then
        print_success "Removed: $wrapper"
        removed=$((removed + 1))
      else
        print_error "Failed to remove: $wrapper"
      fi
    else
      print_info "Not found: $wrapper (already removed)"
    fi
  done
  
  if [ $removed -gt 0 ]; then
    print_success "Removed $removed wrapper command(s)"
  fi
  echo ""
}

# Remove extracted AppImage directory
remove_extracted_dir() {
  print_info "Removing extracted MuseScore directory..."
  
  if [ -d "$MUSESCORE_DIR" ]; then
    local size=$(du -sh "$MUSESCORE_DIR" 2>/dev/null | cut -f1)
    print_info "Directory size: $size"
    
    if rm -rf "$MUSESCORE_DIR" 2>/dev/null; then
      print_success "Removed: $MUSESCORE_DIR"
    else
      print_error "Failed to remove: $MUSESCORE_DIR"
      return 1
    fi
  else
    print_info "Directory not found: $MUSESCORE_DIR (already removed)"
  fi
  echo ""
}

# Remove downloaded AppImage file
remove_appimage() {
  print_info "Checking for downloaded AppImage..."
  
  if [ -f "$APPIMAGE_FILE" ]; then
    local size=$(du -sh "$APPIMAGE_FILE" 2>/dev/null | cut -f1)
    print_info "Found AppImage file ($size): $APPIMAGE_FILE"
    
    read -p "Do you want to remove the AppImage file? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      if rm -f "$APPIMAGE_FILE" 2>/dev/null; then
        print_success "Removed: $APPIMAGE_FILE"
      else
        print_error "Failed to remove: $APPIMAGE_FILE"
      fi
    else
      print_info "Kept: $APPIMAGE_FILE"
    fi
  else
    print_info "AppImage file not found (already removed or moved)"
  fi
  echo ""
}

# Optionally remove dependencies
remove_dependencies() {
  print_warning "Dependencies removal"
  print_info "The following packages were installed:"
  echo "  xvfb, libnss3-dev, libegl1-mesa-dev, libglu1-mesa-dev,"
  echo "  freeglut3-dev, mesa-common-dev, libjack-jackd2-dev,"
  echo "  libxss1, libgconf-2-4, libxtst6, libxrandr2, libasound2-dev"
  echo ""
  print_warning "These packages may be used by other applications!"
  read -p "Do you want to remove these dependencies? (y/N): " -n 1 -r
  echo ""
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Removing dependencies..."
    
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
    
    if sudo apt-get remove -y "${DEPENDENCIES[@]}" 2>/dev/null; then
      print_success "Dependencies removed"
      print_info "Running apt-get autoremove..."
      sudo apt-get autoremove -y
    else
      print_error "Failed to remove some dependencies"
    fi
  else
    print_info "Dependencies kept"
  fi
  echo ""
}

# Verify uninstallation
verify_uninstall() {
  print_info "Verifying uninstallation..."
  
  local issues=0
  
  # Check wrappers
  for wrapper in "${WRAPPER_PATHS[@]}"; do
    if [ -f "$wrapper" ] || [ -L "$wrapper" ]; then
      print_error "Still exists: $wrapper"
      issues=$((issues + 1))
    fi
  done
  
  # Check directory
  if [ -d "$MUSESCORE_DIR" ]; then
    print_error "Still exists: $MUSESCORE_DIR"
    issues=$((issues + 1))
  fi
  
  if [ $issues -eq 0 ]; then
    print_success "Uninstallation verified successfully"
  else
    print_warning "Found $issues issue(s) during verification"
  fi
  echo ""
}

# Validate sudo access
validate_sudo() {
  print_info "This script requires sudo privileges for some operations"
  print_info "Please enter your password to continue..."
  echo ""
  
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

# Main uninstall process
main() {
  validate_sudo
  
  echo "This script will remove:"
  echo "  1. Wrapper commands (/usr/bin/musescore, /usr/bin/mscore)"
  echo "  2. Extracted MuseScore directory ($MUSESCORE_DIR)"
  echo "  3. (Optional) Downloaded AppImage file"
  echo "  4. (Optional) Installed dependencies"
  echo ""
  
  read -p "Do you want to continue? (y/N): " -n 1 -r
  echo ""
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Uninstallation cancelled"
    exit 0
  fi
  
  echo ""
  echo "Starting uninstallation..."
  echo ""
  
  # Execute uninstall steps
  remove_wrappers
  remove_extracted_dir
  remove_appimage
  remove_dependencies
  verify_uninstall
  
  echo "=================================================="
  print_success "Uninstallation completed!"
  echo "=================================================="
}

# Run main function
main