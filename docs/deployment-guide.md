# Ghost CMS Deployment Guide for veluthoor.com

This guide provides step-by-step instructions for self-hosting veluthoor.com with Ghost CMS on Ubuntu 22.04 LTS.

## Prerequisites

### VPS Requirements
- **Provider**: DigitalOcean, Linode, Hetzner, or similar
- **OS**: Ubuntu 22.04 LTS
- **Specifications**: 
  - Minimum 1GB RAM
  - 20GB storage
  - 1 CPU core
- **Domain**: veluthoor.com (with DNS access)

### Local Requirements
- SSH client (Terminal on Mac/Linux, PuTTY on Windows)
- Basic command line knowledge
- Access to domain DNS settings

## Step 1: VPS Setup

### 1.1 Create VPS Instance
1. Sign up for a VPS provider (DigitalOcean recommended)
2. Create a new droplet/server with Ubuntu 22.04 LTS
3. Choose the basic plan (1GB RAM, 1 CPU, 20GB SSD)
4. Note down the server IP address

### 1.2 Initial Server Access
```bash
# SSH into your VPS (replace with your actual IP)
ssh root@YOUR_SERVER_IP

# Create a new user (recommended)
adduser ghostadmin
usermod -aG sudo ghostadmin

# Switch to the new user
su - ghostadmin
```

### 1.3 Update System
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git
```

## Step 2: Export Current Ghost Site

### 2.1 Export Content
1. Log into your current Ghost admin panel
2. Go to **Settings** → **Labs**
3. Click **Export** to download your content
4. Save the JSON file to your local machine

### 2.2 Download Theme
1. In Ghost admin, go to **Design** → **Themes**
2. Download your current theme
3. Save the theme files to your local machine

### 2.3 Backup Images
1. Download all images from your current site
2. Organize them in a folder structure

## Step 3: Install Ghost CMS

### 3.1 Install Dependencies
```bash
# Install required packages
sudo apt install -y nginx mysql-server nodejs npm

# Install Ghost CLI
sudo npm install -g ghost-cli
```

### 3.2 Create Ghost Directory
```bash
# Create and set permissions
sudo mkdir -p /var/www/ghost
sudo chown $USER:$USER /var/www/ghost
cd /var/www/ghost
```

### 3.3 Install Ghost
```bash
# Install Ghost CMS
ghost install --url https://veluthoor.com --db mysql --dbhost localhost --dbuser ghost --dbpass YOUR_SECURE_PASSWORD --dbname ghost_production --start
```

## Step 4: Configure Nginx

### 4.1 Create Nginx Configuration
```bash
# Copy the provided nginx configuration
sudo cp /path/to/nginx.conf /etc/nginx/sites-available/veluthoor.com
sudo ln -s /etc/nginx/sites-available/veluthoor.com /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

### 4.2 Test and Reload Nginx
```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Step 5: SSL Certificate Setup

### 5.1 Install Certbot
```bash
sudo apt install -y certbot python3-certbot-nginx
```

### 5.2 Obtain SSL Certificate
```bash
# Make sure your domain points to the server IP first
sudo certbot --nginx -d veluthoor.com -d www.veluthoor.com --non-interactive --agree-tos --email admin@veluthoor.com
```

### 5.3 Set Up Auto-Renewal
```bash
# Test auto-renewal
sudo certbot renew --dry-run

# Add to crontab
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

## Step 6: Import Content

### 6.1 Access Ghost Admin
1. Open https://veluthoor.com/ghost
2. Create your admin account
3. Note down the credentials

### 6.2 Import Content
1. Go to **Settings** → **Labs**
2. Click **Import** and upload your JSON export
3. Wait for the import to complete

### 6.3 Upload Theme
1. Go to **Design** → **Themes**
2. Upload your custom theme
3. Activate the theme

## Step 7: Security Hardening

### 7.1 Configure Firewall
```bash
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 2368
```

### 7.2 Secure SSH
```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Set these values:
# PermitRootLogin no
# PasswordAuthentication no
# PubkeyAuthentication yes

sudo systemctl restart sshd
```

### 7.3 Set Up SSH Keys (Recommended)
```bash
# On your local machine, generate SSH key
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Copy to server
ssh-copy-id ghostadmin@YOUR_SERVER_IP
```

## Step 8: Backup System

### 8.1 Create Backup Script
```bash
# Copy the provided backup script
sudo cp /path/to/backup.sh /usr/local/bin/ghost-backup
sudo chmod +x /usr/local/bin/ghost-backup
```

### 8.2 Set Up Automated Backups
```bash
# Add to crontab for daily backups
echo "0 2 * * * /usr/local/bin/ghost-backup" | sudo crontab -
```

### 8.3 Test Backup
```bash
sudo /usr/local/bin/ghost-backup
```

## Step 9: Monitoring and Maintenance

### 9.1 Set Up Log Monitoring
```bash
# Check Ghost logs
sudo journalctl -u ghost_veluthoor-com -f

# Check Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 9.2 Create Update Script
```bash
# Copy the provided update script
sudo cp /path/to/update.sh /usr/local/bin/ghost-update
sudo chmod +x /usr/local/bin/ghost-update
```

### 9.3 Set Up Monitoring
```bash
# Install monitoring tools
sudo apt install -y htop iotop

# Check system resources
htop
df -h
free -h
```

## Step 10: DNS Configuration

### 10.1 Update DNS Records
1. Log into your domain registrar
2. Go to DNS settings
3. Create/update A record:
   - **Name**: @ (or leave blank)
   - **Value**: YOUR_SERVER_IP
   - **TTL**: 300 (or default)
4. Create CNAME record for www:
   - **Name**: www
   - **Value**: veluthoor.com
   - **TTL**: 300S

### 10.2 Verify DNS
```bash
# Check DNS propagation
nslookup veluthoor.com
dig veluthoor.com
```

## Troubleshooting

### Common Issues

#### Ghost Won't Start
```bash
cd /var/www/ghost
ghost doctor
ghost restart
```

#### SSL Certificate Issues
```bash
sudo certbot --nginx -d veluthoor.com
sudo systemctl reload nginx
```

#### Database Connection Errors
```bash
sudo systemctl restart mysql
cd /var/www/ghost
ghost restart
```

#### Nginx Configuration Errors
```bash
sudo nginx -t
sudo systemctl restart nginx
```

### Performance Optimization

#### Enable Gzip Compression
Already configured in the nginx.conf file.

#### Optimize Images
```bash
# Install image optimization tools
sudo apt install -y jpegoptim optipng
```

#### Database Optimization
```bash
# Optimize MySQL
sudo mysql_secure_installation
```

## Maintenance Schedule

### Daily
- Check system logs for errors
- Monitor disk space usage

### Weekly
- Review security logs
- Check for system updates
- Test backup restoration

### Monthly
- Update Ghost CMS
- Review and rotate logs
- Check SSL certificate expiration

### Quarterly
- Security audit
- Performance review
- Disaster recovery test

## Security Checklist

- [ ] UFW firewall enabled
- [ ] Root SSH login disabled
- [ ] SSH keys configured
- [ ] SSL certificate installed
- [ ] Regular backups scheduled
- [ ] Ghost admin password changed
- [ ] Database password changed
- [ ] Nginx security headers configured
- [ ] Fail2ban installed and configured
- [ ] Automatic security updates enabled

## Support and Resources

### Useful Commands
```bash
# Ghost management
ghost start|stop|restart
ghost doctor
ghost update

# System monitoring
htop
df -h
free -h
sudo journalctl -u ghost_veluthoor-com

# Backup and restore
sudo /usr/local/bin/ghost-backup
ghost backup
ghost restore
```

### Documentation Links
- [Ghost Documentation](https://ghost.org/docs/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)

### Emergency Contacts
- VPS Provider Support
- Domain Registrar Support
- Ghost Community Forum

## Next Steps

1. **Test Everything**: Verify all functionality works correctly
2. **Monitor Performance**: Set up monitoring and alerting
3. **Document Configuration**: Keep notes of any custom settings
4. **Plan for Growth**: Consider scaling options as traffic grows
5. **Regular Maintenance**: Stick to the maintenance schedule

Remember to keep your system updated and monitor it regularly for optimal performance and security. 