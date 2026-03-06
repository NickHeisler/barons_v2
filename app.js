#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR/server"

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is not installed. Install it from https://nodejs.org and re-run."
  read -p "Press Enter to exit..." _
  exit 1
fi

if [ ! -d node_modules ]; then
  echo "Installing dependencies..."
  npm install
fi

echo "Starting The Barons on http://localhost:5173"
node index.js
