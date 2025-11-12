#!/bin/bash
# MuseScore 3.6.2 CLI wrapper script
# This script wraps the extracted AppImage with xvfb-run for headless operation

MUSESCORE_APPRUN="$HOME/mscore-3.6.2/AppRun"
XVFB_PID=""

# Cleanup function
cleanup() {
  local exit_code=$?
  
  # Kill any orphaned Xvfb processes started by this script
  if [ -n "$XVFB_PID" ] && kill -0 "$XVFB_PID" 2>/dev/null; then
    kill "$XVFB_PID" 2>/dev/null
    wait "$XVFB_PID" 2>/dev/null
  fi
  
  exit $exit_code
}

# Set up trap to catch exits and signals
trap cleanup EXIT INT TERM

# Check if AppRun exists
if [ ! -f "$MUSESCORE_APPRUN" ]; then
  echo "Error: MuseScore AppRun not found at $MUSESCORE_APPRUN" >&2
  exit 1
fi

# Check if xvfb-run is available
if ! command -v xvfb-run &> /dev/null; then
  echo "Error: xvfb-run is not installed" >&2
  exit 1
fi

# Run MuseScore with xvfb-run, passing all arguments
# explicitly unset QT_QPA_PLATFORM to avoid conflicts
env -u QT_QPA_PLATFORM xvfb-run -a "$MUSESCORE_APPRUN" "$@"
EXIT_CODE=$?

# Store the xvfb-run PID for cleanup (though xvfb-run handles its own cleanup)
# This is a safety net in case xvfb-run fails to clean up
XVFB_PID=$(pgrep -P $$ Xvfb 2>/dev/null | head -1)

exit $EXIT_CODE