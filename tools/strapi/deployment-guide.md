# Strapi + Vite (React Admin) Deployment Guide

Complete step-by-step guide for deploying Strapi + Vite (React Admin) on Ubuntu server from scratch, including error handling and troubleshooting.

---

## 🛠 Installation Steps

### 1. Update Server + Install Essentials

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git ufw build-essential
```

---

### 2. Install Node.js + npm

Most current Strapi versions work with Node.js 18 (you can use 20 depending on your version).

```bash
# Add official repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node + npm
sudo apt install -y nodejs

# Verify installation
node -v
npm -v
```

🟢 **If you get "npm: command not found" error** → Add path to PATH:

```bash
export PATH=$PATH:/usr/bin:/usr/local/bin:/bin
```

---

### 3. Setup MySQL

```bash
sudo apt install -y mysql-server
sudo mysql_secure_installation
```

Enter MySQL:

```bash
mysql -u root -p
```

Create database and user:

```sql
CREATE DATABASE strapi_db;
CREATE USER 'strapi_user'@'localhost' IDENTIFIED BY 'StrongPassword123!';
GRANT ALL PRIVILEGES ON strapi_db.* TO 'strapi_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

---

### 4. Clone Project from Git

```bash
cd /var/www
git clone https://your-repo-url.git fregys
cd fregys
```

---

### 5. Install Dependencies (Strapi & Admin)

**Strapi:**

```bash
cd /var/www/fregys/strapi
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
```

**Vite (React Admin):**

```bash
cd /var/www/fregys/fregys-admin
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
```

⚠️ **If you get "Killed" error** → Server is low on RAM. Solution:

```bash
# Add 2GB Swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify
free -h
```

---

### 6. Configure Strapi Database Connection

In Strapi's `config/database.js` or `.env` file:

```env
DATABASE_CLIENT=mysql
DATABASE_NAME=strapi_db
DATABASE_HOST=127.0.0.1
DATABASE_PORT=3306
DATABASE_USERNAME=strapi_user
DATABASE_PASSWORD=StrongPassword123!
```

---

### 7. First Time Project Startup

**Strapi:**

```bash
cd /var/www/fregys/strapi
npm run build
npm run develop   # or npm run start for production
```

**Vite Admin:**

```bash
cd /var/www/fregys/fregys-admin
npm run dev       # for development
npm run build     # for production
```

---

### 8. Permanent Deployment with PM2

```bash
sudo npm install -g pm2

# Strapi
cd /var/www/fregys/strapi
pm2 start npm --name "strapi" -- run start

# Vite Admin
cd /var/www/fregys/fregys-admin
pm2 start npm --name "fregys-admin" -- run preview

# Save processes
pm2 save
pm2 startup
```

---

### 9. Setup Nginx (Reverse Proxy)

```bash
sudo apt install -y nginx
sudo nano /etc/nginx/sites-available/fregys
```

Add configuration:

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:4173; # Vite preview
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
    }

    location /api {
        proxy_pass http://localhost:1337; # Strapi
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
    }
}
```

Enable site:

```bash
sudo ln -s /etc/nginx/sites-available/fregys /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## 🔧 Common Error Solutions

### Error Fixes:
- **`npm: command not found`** → Install Node.js or add to PATH
- **`Killed` during npm install** → Server out of RAM → Add Swap memory
- **`[vite] error while updating dependencies: Error: The service was stopped`** → Delete `node_modules` + `package-lock.json` → Run `npm install` again
- **Broken pipe / timeout (SSH disconnects)** → Add to `~/.ssh/config`:

```ssh
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 120
```

---

## 🚀 Automated Script Option

Would you like a complete bash script that automates all these steps (including Swap creation + Node installation + DB setup + PM2) to save time?