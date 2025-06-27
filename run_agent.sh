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

python -c "
import os
import subprocess
import sys
import venv

# Define paths
project_dir = '$PROJECT_DIR'
python_script = '$PYTHON_SCRIPT'
venv_dir = os.path.join(project_dir, 'venv')
venv_python = os.path.join(venv_dir, 'bin' if os.name != 'nt' else 'Scripts', 'python')

# Validate Python script exists
if not os.path.isfile(os.path.join(project_dir, python_script)):
    print(f'Error: Python script {python_script} not found in {project_dir}', file=sys.stderr)
    sys.exit(1)

# Create virtual environment if it doesn't exist
if not os.path.exists(venv_dir):
    print('Creating virtual environment...')
    venv.create(venv_dir, with_pip=True)

# Check if uv is installed in the virtual environment
try:
    subprocess.run([venv_python, '-m', 'uv', '--version'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
except (FileNotFoundError, subprocess.CalledProcessError):
    print('Installing uv in virtual environment...')
    try:
        subprocess.run([venv_python, '-m', 'pip', 'install', 'uv'], check=True)
    except subprocess.CalledProcessError as e:
        print(f'Error: Failed to install uv: {e}', file=sys.stderr)
        sys.exit(1)

# Change to project directory
try:
    os.chdir(project_dir)
except OSError as e:
    print(f'Error: Could not change to directory {project_dir}: {e}', file=sys.stderr)
    sys.exit(1)

# Run uv sync and then uv run for the specified script
try:
    subprocess.run([venv_python, '-m', 'uv', 'sync'], check=True)
    subprocess.run([venv_python, '-m', 'uv', 'run', python_script], check=True)
except FileNotFoundError:
    print('Error: \"uv\" not found even after installation attempt.', file=sys.stderr)
    sys.exit(1)
except subprocess.CalledProcessError as e:
    print(f'Error: Command failed: {e}', file=sys.stderr)
    sys.exit(1)
"