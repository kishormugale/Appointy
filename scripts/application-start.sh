#!/bin/bash
set -euo pipefail

echo "=== ApplicationStart: Starting application ==="

# Create systemd service if not exists
cat > /etc/systemd/system/appointy-backend.service << 'EOF'
[Unit]
Description=Appointy Backend API
After=network.target

[Service]
Type=simple
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/appointy/backend
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=production

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=/opt/appointy/backend /tmp /var/log

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the service
systemctl daemon-reload
systemctl enable appointy-backend
systemctl start appointy-backend

echo "=== ApplicationStart: Complete ==="
