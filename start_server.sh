#!/bin/bash

# Start myAnalytics API server on port 8765
# Usage: ./start_server.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set the port
export PORT=8765

# Change to the project directory
cd "$SCRIPT_DIR"

# Check if Julia is available
if ! command -v julia &> /dev/null; then
    echo "Error: Julia is not installed or not in PATH"
    exit 1
fi

echo "Starting myAnalytics API server on port $PORT..."
echo "API will be available at:"
echo "  - Local: http://localhost:$PORT"
echo "  - Network: http://$(hostname -I | awk '{print $1}'):$PORT"
echo "Swagger documentation: http://localhost:$PORT/docs"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server
julia --project src/myAnalytics.jl

