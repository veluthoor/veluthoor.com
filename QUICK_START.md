# Quick Start Guide - Self-Hosting veluthoor.com with Ghost CMS

## 🚀 Immediate Deployment Steps

### 1. Prepare Your VPS
```bash
# SSH into your Ubuntu 22.04 VPS
ssh root@YOUR_VPS_IP

# Create admin user
adduser ghostadmin
usermod -aG sudo ghostadmin
su - ghostadmin
```

### 2. Clone This Repository
```bash
# On your VPS
git clone <your-repo-url>
cd my-app
```

### 3. Run Automated Installation
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run the main installation script
./scripts/install.sh
```

### 4. Configure DNS
- Point `veluthoor.com` A record to your VPS IP
- Add CNAME for `www.veluthoor.com` → `veluthoor.com`

### 5. Import Your Content
1. Access https://veluthoor.com/ghost
2. Create admin account
3. Import your JSON export from current site
4. Upload your custom theme

### 6. Security Hardening
```bash
# Run security script
./scripts/security.sh
```

## 📋 Pre-Deployment Checklist

### Export Current Site
- [ ] Export content from current Ghost admin
- [ ] Download custom theme
- [ ] Backup all images and assets

### VPS Requirements
- [ ] Ubuntu 22.04 LTS
- [ ] Minimum 1GB RAM
- [ ] 20GB storage
- [ ] Public IP address

### Domain Setup
- [ ] Domain registrar access
- [ ] DNS management access
- [ ] Domain points to VPS IP

## 🔧 Post-Deployment Tasks

### Immediate Actions
1. **Change default passwords**
2. **Test backup system**: `sudo /usr/local/bin/ghost-backup`
3. **Verify SSL certificate**: `sudo certbot certificates`
4. **Check security**: `/usr/local/bin/security-check`

### Weekly Maintenance
```bash
# Update Ghost
sudo /usr/local/bin/ghost-update

# Check system status
htop
df -h
sudo journalctl -u ghost_veluthoor-com
```

### Monthly Tasks
- [ ] Update Ghost CMS
- [ ] Review security logs
- [ ] Test backup restoration
- [ ] Check SSL certificate expiration

## 🆘 Quick Troubleshooting

### Ghost Won't Start
```bash
cd /var/www/ghost
ghost doctor
ghost restart
```

### SSL Issues
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

## 📞 Support Commands

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

## 🎯 Success Indicators

Your deployment is successful when:
- ✅ https://veluthoor.com loads your site
- ✅ https://veluthoor.com/ghost shows admin panel
- ✅ SSL certificate is valid (green lock)
- ✅ Daily backups are running
- ✅ Security script completed without errors

## 📚 Next Steps

1. **Read the full documentation**: `docs/deployment-guide.md`
2. **Set up monitoring alerts**
3. **Create disaster recovery plan**
4. **Document any custom configurations**

---

**Need help?** Check the troubleshooting section in `docs/deployment-guide.md` or review the logs for specific error messages. 