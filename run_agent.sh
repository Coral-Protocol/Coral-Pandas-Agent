#!/bin/bash

# Cross-platform shell script to set up a virtual environment and run a specified Python script
# Usage: ./run_agent.sh <python_script_path>

# Check if Python script path is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <python_script_path>" >&2
    exit 1
fi
PYTHON_SCRIPT="$1"

# Determine project directory from script location
SCRIPT_DIR=$(dirname "$(realpath "$0" 2>/dev/null || readlink -f "$0" 2>/dev/null || echo "$0")")
PROJECT_DIR="$SCRIPT_DIR"

# Detect operating system
OS=$(uname -s)
case "$OS" in
  Linux*|Darwin*) PLATFORM="unix" ;;
  CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
  *) echo "Error: Unsupported OS: $OS" >&2; exit 1 ;;
esac

# Set virtual environment paths
if [ "$PLATFORM" = "windows" ]; then
  VENV_DIR="$PROJECT_DIR/venv/Scripts"
  VENV_PYTHON="$VENV_DIR/python.exe"
  UV_EXEC="$VENV_DIR/uv.exe"
  # Convert Unix-style path to Windows-style for Python script if needed
  PYTHON_SCRIPT=$(echo "$PYTHON_SCRIPT" | sed 's|/|\\|g')
else
  VENV_DIR="$PROJECT_DIR/venv/bin"
  VENV_PYTHON="$VENV_DIR/python"
  UV_EXEC="$VENV_DIR/uv"
fi

# Validate Python script exists
if [ ! -f "$PROJECT_DIR/$PYTHON_SCRIPT" ]; then
  echo "Error: Python script $PYTHON_SCRIPT not found in $PROJECT_DIR" >&2
  exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$PROJECT_DIR/venv" ]; then
  echo "Creating virtual environment in $PROJECT_DIR/venv..."
  python3 -m venv "$PROJECT_DIR/venv" || { echo "Error: Failed to create virtual environment" >&2; exit 1; }
fi

# Check if uv is installed in the virtual environment
if ! "$VENV_PYTHON" -m uv --version >/dev/null 2>&1; then
  echo "Installing uv in virtual environment..."
  "$VENV_PYTHON" -m pip install uv || { echo "Error: Failed to install uv" >&2; exit 1; }
fi

# Change to project directory
cd "$PROJECT_DIR" || { echo "Error: Could not change to directory $PROJECT_DIR" >&2; exit 1; }

# Run uv sync
echo "Running uv sync in $PROJECT_DIR..."
"$VENV_PYTHON" -m uv sync || { echo "Error: uv sync failed" >&2; exit 1; }

# Run the Python script with uv
echo "Running $PYTHON_SCRIPT..."
"$VENV_PYTHON" -m uv run "$PYTHON_SCRIPT" || { echo "Error: Failed to run $PYTHON_SCRIPT" >&2; exit 1; }

echo "Script executed successfully."