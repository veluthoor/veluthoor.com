#!/bin/bash

# Self-Hosting veluthoor.com with Ghost CMS - Installation Script
# This script automates the installation of Ghost CMS on Ubuntu 22.04 LTS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="veluthoor.com"
GHOST_DIR="/var/www/ghost"
BACKUP_DIR="/var/www/backups"
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
GHOST_DB_PASSWORD=$(openssl rand -base64 32)

echo -e "${GREEN}Starting Ghost CMS installation for ${DOMAIN}...${NC}"

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
if [[ "$UBUNTU_VERSION" != "22.04" ]]; then
    print_warning "This script is designed for Ubuntu 22.04. Current version: $UBUNTU_VERSION"
fi

print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

print_status "Installing required dependencies..."
sudo apt install -y nginx mysql-server nodejs npm curl wget unzip

print_status "Installing Ghost CLI..."
sudo npm install -g ghost-cli

print_status "Creating Ghost directory..."
sudo mkdir -p $GHOST_DIR
sudo chown $USER:$USER $GHOST_DIR
cd $GHOST_DIR

print_status "Installing Ghost CMS..."
ghost install --url https://$DOMAIN --db mysql --dbhost localhost --dbuser ghost --dbpass $GHOST_DB_PASSWORD --dbname ghost_production --start

print_status "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    location / {
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:2368;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

print_status "Installing Let's Encrypt SSL..."
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

print_status "Setting up automated SSL renewal..."
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -

print_status "Creating backup directory..."
sudo mkdir -p $BACKUP_DIR
sudo chown $USER:$USER $BACKUP_DIR

print_status "Setting up UFW firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 2368

print_status "Configuring security settings..."
# Disable root SSH login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

print_status "Creating backup script..."
sudo tee /usr/local/bin/ghost-backup > /dev/null <<'EOF'
#!/bin/bash
BACKUP_DIR="/var/www/backups"
GHOST_DIR="/var/www/ghost"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup Ghost content
cd $GHOST_DIR
ghost backup --filename $BACKUP_DIR/ghost_backup_$DATE.zip

# Backup database
mysqldump -u ghost -p$(grep -o '"password":"[^"]*"' $GHOST_DIR/config.production.json | cut -d'"' -f4) ghost_production > $BACKUP_DIR/database_backup_$DATE.sql

# Backup themes
cp -r $GHOST_DIR/content/themes $BACKUP_DIR/themes_backup_$DATE

# Clean old backups (keep last 7 days)
find $BACKUP_DIR -name "*.zip" -mtime +7 -delete
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "themes_backup_*" -mtime +7 -exec rm -rf {} \;

echo "Backup completed: $DATE"
EOF

sudo chmod +x /usr/local/bin/ghost-backup

print_status "Setting up daily backups..."
echo "0 2 * * * /usr/local/bin/ghost-backup" | sudo crontab -

print_status "Creating update script..."
sudo tee /usr/local/bin/ghost-update > /dev/null <<'EOF'
#!/bin/bash
cd /var/www/ghost
ghost update
sudo systemctl restart nginx
echo "Ghost updated successfully"
EOF

sudo chmod +x /usr/local/bin/ghost-update

print_status "Installation completed successfully!"
echo -e "${GREEN}Ghost CMS is now running at: https://$DOMAIN${NC}"
echo -e "${GREEN}Admin panel: https://$DOMAIN/ghost${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Import your content from the backup"
echo "2. Upload your custom theme"
echo "3. Configure your admin account"
echo "4. Test the backup system: sudo /usr/local/bin/ghost-backup"
echo "5. Update Ghost when needed: sudo /usr/local/bin/ghost-update"

# Save configuration
cat > /tmp/ghost-config.txt <<EOF
Domain: $DOMAIN
Ghost Directory: $GHOST_DIR
Backup Directory: $BACKUP_DIR
Database Password: $GHOST_DB_PASSWORD
Admin URL: https://$DOMAIN/ghost
EOF

print_status "Configuration saved to /tmp/ghost-config.txt" 