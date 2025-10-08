# 🚀 DevOps Quick Reference Guide

Essential commands and troubleshooting for server administration, deployment, and development operations.

## 📁 File Management

```bash
# Move/rename
mv old_name new_name

# Copy to another server
scp file.txt user@server:/path/

# Delete file
rm filename

# Delete folder
rm -rf foldername

# View file content
cat filename

# Compress folder
zip -r archive.zip folder/
```

## 🔧 Service Management

```bash
# Nginx
sudo systemctl restart nginx
nginx -t

# MySQL
mysql -u root -p
sudo systemctl restart mysql

# PHP-FPM
sudo systemctl restart php8.1-fpm
```

## 🗄️ Database Operations

```bash
# Backup
mysqldump dbname > backup.sql

# Restore
mysql dbname < backup.sql

# Inside MySQL
CREATE DATABASE dbname;
DROP DATABASE dbname;
SHOW DATABASES;
USE dbname;
```

## 🌐 Git Commands

```bash
# New branch
git checkout -b new-branch

# Merge branches
git checkout main && git merge feature

# Undo commit
git reset --soft HEAD~

# Clear cache
git rm -r --cached .
```

## 🔐 SSH & SSL

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "email@example.com"

# View public key
cat ~/.ssh/id_rsa.pub

# Test GitHub connection
ssh -T git@github.com

# Let's Encrypt certificate
sudo certbot --nginx -d domain.com
```

## 🚀 WordPress Deployment

```bash
# Download WordPress
wget https://wordpress.org/latest.zip
unzip latest.zip

# Set permissions
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# Database setup
mysql -u root -p
CREATE DATABASE wordpress;
CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON wordpress.* TO 'wpuser'@'localhost';
```

## 🔍 Troubleshooting

```bash
# Nginx logs
sudo tail -f /var/log/nginx/error.log

# PHP logs
sudo tail -f /var/log/php8.1-fpm.log

# Check ports
netstat -tulpn | grep :80

# Check service status
sudo systemctl status nginx mysql php8.1-fpm

# Check disk space
df -h

# Check memory usage
free -h
```

## 📊 Performance Monitoring

```bash
# CPU usage
top
htop

# Active processes
ps aux | grep nginx

# Check connections
ss -tulpn

# Test website speed
curl -o /dev/null -s -w "%{time_total}\n" http://domain.com
```

## 🛡️ Security

```bash
# System update
sudo apt update && sudo apt upgrade

# Firewall management
sudo ufw enable
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw status

# Check logged in users
who
w
last

# Login attempt logs
sudo tail /var/log/auth.log
sudo grep "Failed password" /var/log/auth.log

# File permissions
chmod 644 file.txt    # Read/write owner, read others
chmod 755 script.sh   # Execute permissions
chown user:group file.txt
```

## 🐳 Docker Commands

```bash
# Container management
docker ps                    # List running containers
docker ps -a                 # List all containers
docker stop container_name   # Stop container
docker rm container_name     # Remove container

# Image management
docker images               # List images
docker pull image:tag       # Pull image
docker rmi image_id         # Remove image

# Docker Compose
docker-compose up -d        # Start services in background
docker-compose down         # Stop and remove services
docker-compose logs -f      # Follow logs
```

## 🔄 Process Management

```bash
# PM2 (Node.js)
pm2 start app.js --name "myapp"
pm2 list                    # List processes
pm2 restart myapp          # Restart process
pm2 stop myapp             # Stop process
pm2 logs myapp             # View logs
pm2 save                   # Save current processes
pm2 startup                # Setup startup script

# System processes
ps aux | grep process_name  # Find process
kill -9 PID                # Force kill process
killall process_name       # Kill all instances
nohup command &            # Run in background
```

## 📦 Package Management

```bash
# APT (Ubuntu/Debian)
sudo apt update            # Update package list
sudo apt upgrade           # Upgrade packages
sudo apt install package  # Install package
sudo apt remove package   # Remove package
sudo apt autoremove       # Remove unused packages

# NPM/Node.js
npm install package        # Install package locally
npm install -g package     # Install globally
npm list                   # List installed packages
npm outdated              # Check for updates
npm audit                 # Security audit

# Composer (PHP)
composer install          # Install dependencies
composer update           # Update dependencies
composer require package  # Add new package
```

## 🔧 System Information

```bash
# System details
uname -a                  # System information
lsb_release -a           # OS version
uptime                   # System uptime
whoami                   # Current user

# Hardware info
lscpu                    # CPU information
free -h                  # Memory usage
df -h                    # Disk usage
lsblk                    # Block devices
fdisk -l                 # Disk partitions

# Network info
ip addr show             # Network interfaces
netstat -tulpn          # Network connections
ss -tulpn               # Socket statistics
ping -c 4 google.com    # Test connectivity
```

## 🚨 Emergency Commands

```bash
# Service recovery
sudo systemctl restart nginx
sudo systemctl restart mysql
sudo systemctl restart php8.1-fpm

# Disk space cleanup
sudo apt autoremove
sudo apt autoclean
docker system prune -f
sudo find /var/log -name "*.log" -type f -size +100M

# Process troubleshooting
top                      # Real-time processes
htop                     # Enhanced process viewer
iotop                    # I/O monitoring
netstat -i               # Network interface stats

# Quick fixes
sudo nginx -t && sudo systemctl reload nginx
sudo service mysql restart
sudo systemctl daemon-reload
```

## 📝 Useful Aliases

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
# Navigation
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# System
alias update='sudo apt update && sudo apt upgrade'
alias install='sudo apt install'
alias search='apt search'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Docker shortcuts
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'

# Service management
alias nginx-reload='sudo nginx -t && sudo systemctl reload nginx'
alias nginx-restart='sudo systemctl restart nginx'
alias mysql-restart='sudo systemctl restart mysql'
```
