#!/bin/bash

# Ghost CMS Update Script
# This script updates Ghost CMS and performs system maintenance

set -e

# Configuration
GHOST_DIR="/var/www/ghost"
DOMAIN="veluthoor.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Starting Ghost CMS update process..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# 1. Create backup before update
print_status "Creating backup before update..."
/usr/local/bin/ghost-backup

# 2. Update system packages
print_status "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# 3. Update Node.js and npm if needed
print_status "Checking Node.js version..."
CURRENT_NODE_VERSION=$(node --version | cut -d'v' -f2)
REQUIRED_NODE_VERSION="18.0.0"

if [ "$(printf '%s\n' "$REQUIRED_NODE_VERSION" "$CURRENT_NODE_VERSION" | sort -V | head -n1)" != "$REQUIRED_NODE_VERSION" ]; then
    print_warning "Node.js version $CURRENT_NODE_VERSION is older than recommended $REQUIRED_NODE_VERSION"
    print_status "Updating Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# 4. Update Ghost CLI
print_status "Updating Ghost CLI..."
sudo npm update -g ghost-cli

# 5. Navigate to Ghost directory
cd $GHOST_DIR

# 6. Check current Ghost version
CURRENT_GHOST_VERSION=$(ghost --version)
print_status "Current Ghost version: $CURRENT_GHOST_VERSION"

# 7. Update Ghost
print_status "Updating Ghost CMS..."
ghost update

# 8. Check if update was successful
if [ $? -eq 0 ]; then
    print_status "Ghost update completed successfully"
else
    print_error "Ghost update failed"
    exit 1
fi

# 9. Restart Ghost service
print_status "Restarting Ghost service..."
ghost restart

# 10. Check Ghost status
print_status "Checking Ghost service status..."
if systemctl is-active --quiet ghost_$DOMAIN; then
    print_status "Ghost service is running"
else
    print_error "Ghost service is not running"
    ghost doctor
    exit 1
fi

# 11. Update Nginx configuration if needed
print_status "Checking Nginx configuration..."
sudo nginx -t
if [ $? -eq 0 ]; then
    print_status "Nginx configuration is valid"
    sudo systemctl reload nginx
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# 12. Renew SSL certificate
print_status "Checking SSL certificate..."
sudo certbot renew --dry-run

# 13. Clean up old packages
print_status "Cleaning up old packages..."
sudo apt autoremove -y
sudo apt autoclean

# 14. Check disk space
print_status "Checking disk space..."
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    print_warning "Disk usage is high: ${DISK_USAGE}%"
else
    print_status "Disk usage is normal: ${DISK_USAGE}%"
fi

# 15. Check memory usage
print_status "Checking memory usage..."
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.2f%%", $3*100/$2}')
print_status "Memory usage: $MEMORY_USAGE"

# 16. Update log rotation
print_status "Updating log rotation..."
sudo tee /etc/logrotate.d/ghost > /dev/null <<EOF
$GHOST_DIR/content/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ghost ghost
    postrotate
        systemctl reload ghost_$DOMAIN
    endscript
}
EOF

# 17. Check for security updates
print_status "Checking for security updates..."
SECURITY_UPDATES=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)
if [ $SECURITY_UPDATES -gt 0 ]; then
    print_warning "Found $SECURITY_UPDATES security updates available"
    print_status "Installing security updates..."
    sudo apt upgrade -y
fi

# 18. Final status check
print_status "Performing final status check..."
ghost doctor

print_status "Update process completed successfully!"
print_status "Ghost CMS is now running at: https://$DOMAIN"
print_status "Admin panel: https://$DOMAIN/ghost"

# 19. Optional: Send notification
if command -v mail &> /dev/null; then
    echo "Ghost CMS update completed successfully for $DOMAIN at $(date)" | mail -s "Ghost Update Success" admin@$DOMAIN
fi

print_status "Update process completed at $(date)" 