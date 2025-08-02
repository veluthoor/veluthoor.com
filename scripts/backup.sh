#!/bin/bash

# Ghost CMS Backup Script
# This script creates comprehensive backups of Ghost CMS including content, database, themes, and images

set -e

# Configuration
GHOST_DIR="/var/www/ghost"
BACKUP_DIR="/var/www/backups"
DOMAIN="veluthoor.com"
RETENTION_DAYS=7

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

# Create timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="ghost_backup_$TIMESTAMP"

print_status "Starting backup process for $DOMAIN..."

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Check if Ghost is running
if ! systemctl is-active --quiet ghost_$DOMAIN; then
    print_warning "Ghost service is not running"
fi

# 1. Create Ghost content backup
print_status "Creating Ghost content backup..."
cd $GHOST_DIR
if ghost backup --filename $BACKUP_DIR/${BACKUP_NAME}.zip; then
    print_status "Ghost content backup completed"
else
    print_error "Ghost content backup failed"
    exit 1
fi

# 2. Backup database
print_status "Backing up database..."
# Extract database password from Ghost config
DB_PASSWORD=$(grep -o '"password":"[^"]*"' $GHOST_DIR/config.production.json | cut -d'"' -f4)
if [ -z "$DB_PASSWORD" ]; then
    print_error "Could not extract database password from Ghost config"
    exit 1
fi

mysqldump -u ghost -p$DB_PASSWORD ghost_production > $BACKUP_DIR/database_${BACKUP_NAME}.sql
if [ $? -eq 0 ]; then
    print_status "Database backup completed"
else
    print_error "Database backup failed"
    exit 1
fi

# 3. Backup themes directory
print_status "Backing up themes..."
if [ -d "$GHOST_DIR/content/themes" ]; then
    tar -czf $BACKUP_DIR/themes_${BACKUP_NAME}.tar.gz -C $GHOST_DIR/content themes
    print_status "Themes backup completed"
else
    print_warning "Themes directory not found"
fi

# 4. Backup images and uploads
print_status "Backing up images and uploads..."
if [ -d "$GHOST_DIR/content/images" ]; then
    tar -czf $BACKUP_DIR/images_${BACKUP_NAME}.tar.gz -C $GHOST_DIR/content images
    print_status "Images backup completed"
else
    print_warning "Images directory not found"
fi

# 5. Backup Ghost configuration
print_status "Backing up Ghost configuration..."
cp $GHOST_DIR/config.production.json $BACKUP_DIR/config_${BACKUP_NAME}.json
print_status "Configuration backup completed"

# 6. Create backup manifest
print_status "Creating backup manifest..."
cat > $BACKUP_DIR/manifest_${BACKUP_NAME}.txt <<EOF
Ghost CMS Backup Manifest
=========================
Domain: $DOMAIN
Timestamp: $TIMESTAMP
Backup Date: $(date)

Files Created:
- ${BACKUP_NAME}.zip (Ghost content)
- database_${BACKUP_NAME}.sql (Database)
- themes_${BACKUP_NAME}.tar.gz (Themes)
- images_${BACKUP_NAME}.tar.gz (Images)
- config_${BACKUP_NAME}.json (Configuration)
- manifest_${BACKUP_NAME}.txt (This file)

System Information:
- Ghost Version: $(ghost --version)
- Node Version: $(node --version)
- MySQL Version: $(mysql --version | cut -d' ' -f6)

Backup Size: $(du -sh $BACKUP_DIR/*${BACKUP_NAME}* | awk '{sum+=$1} END {print sum}')
EOF

print_status "Backup manifest created"

# 7. Clean old backups
print_status "Cleaning old backups (keeping last $RETENTION_DAYS days)..."
find $BACKUP_DIR -name "*.zip" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.sql" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.json" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "manifest_*.txt" -mtime +$RETENTION_DAYS -delete

# 8. Calculate backup size
TOTAL_SIZE=$(du -sh $BACKUP_DIR | cut -f1)
print_status "Backup completed successfully!"
print_status "Total backup directory size: $TOTAL_SIZE"
print_status "Backup files saved to: $BACKUP_DIR"

# 9. Optional: Upload to remote storage (uncomment if needed)
# print_status "Uploading backup to remote storage..."
# rsync -avz $BACKUP_DIR/ user@remote-server:/backups/ghost/

# 10. Send notification (if configured)
if command -v mail &> /dev/null; then
    echo "Ghost backup completed successfully for $DOMAIN at $(date)" | mail -s "Ghost Backup Success" admin@$DOMAIN
fi

print_status "Backup process completed at $(date)" 