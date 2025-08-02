# 🚀 Deployment Checklist - veluthoor.com Ghost CMS

## ✅ Pre-Deployment Checklist

### 📋 Export Current Site
- [ ] **Export Ghost content** (Settings → Labs → Export)
- [ ] **Download custom theme** (Design → Themes)
- [ ] **Backup all images** and assets
- [ ] **Note current admin credentials**

### 🖥️ VPS Requirements
- [ ] **Ubuntu 22.04 LTS** server
- [ ] **Minimum 1GB RAM**, 20GB storage
- [ ] **Public IP address**
- [ ] **SSH access** configured
- [ ] **Domain DNS access** (veluthoor.com)

### 🔧 Local Setup
- [ ] **SSH client** installed (Terminal/PuTTY)
- [ ] **Git** installed locally
- [ ] **Repository cloned** to local machine

## 🚀 Deployment Steps

### Step 1: VPS Setup
```bash
# SSH into your VPS
ssh root@YOUR_VPS_IP

# Create admin user
adduser ghostadmin
usermod -aG sudo ghostadmin
su - ghostadmin
```

### Step 2: Clone Repository
```bash
# On your VPS
git clone <your-repo-url>
cd my-app
```

### Step 3: Run Installation
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run automated installation
./scripts/install.sh
```

### Step 4: Configure DNS
- [ ] **Point A record** veluthoor.com → VPS_IP
- [ ] **Add CNAME** www.veluthoor.com → veluthoor.com
- [ ] **Wait for DNS propagation** (up to 24 hours)

### Step 5: Import Content
- [ ] **Access** https://veluthoor.com/ghost
- [ ] **Create admin account**
- [ ] **Import JSON export** from current site
- [ ] **Upload custom theme**
- [ ] **Test all functionality**

### Step 6: Security Hardening
```bash
# Run security script
./scripts/security.sh
```

## ✅ Post-Deployment Verification

### 🌐 Website Functionality
- [ ] **https://veluthoor.com** loads correctly
- [ ] **SSL certificate** is valid (green lock)
- [ ] **Admin panel** accessible at /ghost
- [ ] **All posts and pages** imported correctly
- [ ] **Custom theme** working properly
- [ ] **Images and assets** loading correctly

### 🔒 Security Verification
- [ ] **HTTPS redirect** working
- [ ] **Security headers** present
- [ ] **Firewall** enabled and configured
- [ ] **SSH key authentication** working
- [ ] **Fail2ban** installed and running

### 💾 Backup System
- [ ] **Test backup**: `sudo /usr/local/bin/ghost-backup`
- [ ] **Check backup files** in /var/www/backups
- [ ] **Verify cron job**: `crontab -l`

### 📊 System Health
- [ ] **Disk space**: `df -h`
- [ ] **Memory usage**: `free -h`
- [ ] **Service status**: `systemctl status ghost_veluthoor-com`
- [ ] **Nginx status**: `systemctl status nginx`

## 🔧 Maintenance Commands

### Daily Monitoring
```bash
# Check Ghost logs
sudo journalctl -u ghost_veluthoor-com -f

# Check system resources
htop
df -h
free -h

# Check backup status
ls -la /var/www/backups/
```

### Weekly Tasks
```bash
# Update Ghost
sudo /usr/local/bin/ghost-update

# Check security
/usr/local/bin/security-check

# Review logs
sudo tail -f /var/log/nginx/error.log
```

### Monthly Tasks
- [ ] **Update Ghost CMS**
- [ ] **Review security logs**
- [ ] **Test backup restoration**
- [ ] **Check SSL certificate expiration**

## 🆘 Emergency Procedures

### Ghost Won't Start
```bash
cd /var/www/ghost
ghost doctor
ghost restart
```

### SSL Certificate Issues
```bash
sudo certbot --nginx -d veluthoor.com
sudo systemctl reload nginx
```

### Database Problems
```bash
sudo systemctl restart mysql
cd /var/www/ghost
ghost restart
```

### Restore from Backup
```bash
cd /var/www/ghost
ghost restore /path/to/backup.zip
```

## 📞 Support Information

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

# Logs
sudo journalctl -u ghost_veluthoor-com -f
sudo tail -f /var/log/nginx/error.log

# Backups
sudo /usr/local/bin/ghost-backup
```

### Documentation Files
- **Quick Start**: `QUICK_START.md`
- **Full Guide**: `docs/deployment-guide.md`
- **Troubleshooting**: See deployment guide

### Emergency Contacts
- **VPS Provider Support**
- **Domain Registrar Support**
- **Ghost Community Forum**

## 🎯 Success Criteria

Your deployment is successful when:
- ✅ **Website loads** at https://veluthoor.com
- ✅ **SSL certificate** is valid
- ✅ **Admin panel** accessible
- ✅ **All content** imported correctly
- ✅ **Daily backups** running
- ✅ **Security hardening** completed
- ✅ **Monitoring** in place

---

**🚀 Your Ghost CMS self-hosting solution is ready for production deployment!** 