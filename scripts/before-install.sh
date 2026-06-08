#!/bin/bash
set -euo pipefail

echo "=== BeforeInstall: Stopping existing application ==="

# Stop the app if running
if systemctl is-active --quiet appointy-backend; then
    systemctl stop appointy-backend
fi

# Clean old deployment
rm -rf /opt/appointy/backend/*

echo "=== BeforeInstall: Complete ==="
