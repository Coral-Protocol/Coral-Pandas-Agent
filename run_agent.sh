#!/bin/bash

# Cross-platform shell script to set up a virtual environment and run a specified Python script
# Usage: ./run_agent.sh <python_script_path>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <python_script_path>" >&2
    exit 1
fi
PYTHON_SCRIPT="$1"

SCRIPT_DIR=$(dirname "$(realpath "$0" 2>/dev/null || readlink -f "$0" 2>/dev/null || echo "$0")")
PROJECT_DIR="$SCRIPT_DIR"

# Detect operating system
OS=$(uname -s)
case "$OS" in
  Linux*|Darwin*) PLATFORM="unix" ;;
  CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
  *) echo "Error: Unsupported OS: $OS" >&2; exit 1 ;;
esac

if [ "$PLATFORM" = "windows" ]; then
  VENV_BASE="$PROJECT_DIR/venv"
  VENV_DIR="$VENV_BASE/Scripts"
  VENV_PYTHON="$VENV_DIR/python.exe"
  VENV_PIP="$VENV_DIR/pip.exe"
  UV_EXEC="$VENV_DIR/uv.exe"
  # Convert Unix-style path to Windows-style for Python script if needed
  PYTHON_SCRIPT=$(echo "$PYTHON_SCRIPT" | sed 's|/|\\|g')
else
  VENV_BASE="$PROJECT_DIR/.venv"
  VENV_DIR="$VENV_BASE/bin"
  VENV_PYTHON="$VENV_DIR/python"
  VENV_PIP="$VENV_DIR/pip"
  UV_EXEC="$VENV_DIR/uv"
fi

# Validate Python script exists
if [ ! -f "$PROJECT_DIR/$PYTHON_SCRIPT" ]; then
  echo "Error: Python script $PYTHON_SCRIPT not found in $PROJECT_DIR" >&2
  exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_BASE" ]; then
  echo "Creating virtual environment in $VENV_BASE..."
  python3 -m venv "$VENV_BASE" --with-pip || python3 -m venv "$VENV_BASE" || { echo "Error: Failed to create virtual environment" >&2; exit 1; }
fi

# Ensure pip exists
if [ ! -f "$VENV_PIP" ]; then
  echo "Pip not found, installing with ensurepip..."
  "$VENV_PYTHON" -m ensurepip || { echo "Error: Failed to install pip" >&2; exit 1; }
fi

# Ensure uv exists
if ! "$VENV_PYTHON" -m uv --version >/dev/null 2>&1; then
  echo "Installing uv in virtual environment..."
  "$VENV_PYTHON" -m pip install --upgrade pip 
  "$VENV_PYTHON" -m pip install uv || { echo "Error: Failed to install uv" >&2; exit 1; }
fi

if [ ! -f "$PROJECT_DIR/requirements.txt" ]; then
  touch "$PROJECT_DIR/requirements.txt"
fi
if ! grep -q '^uv' "$PROJECT_DIR/requirements.txt"; then
  echo "uv" >> "$PROJECT_DIR/requirements.txt"
fi

cd "$PROJECT_DIR" || { echo "Error: Could not change to directory $PROJECT_DIR" >&2; exit 1; }

# Run uv sync
echo "Running uv sync in $PROJECT_DIR..."
"$VENV_PYTHON" -m uv sync || { echo "Error: uv sync failed" >&2; exit 1; }

# Run the Python script with uv
echo "Running $PYTHON_SCRIPT..."
"$VENV_PYTHON" -m uv run "$PYTHON_SCRIPT" || { echo "Error: Failed to run $PYTHON_SCRIPT" >&2; exit 1; }

echo "Script executed successfully."
