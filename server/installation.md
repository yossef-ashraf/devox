# Server Software Installation Guide

Complete installation steps for Nginx, Node.js, Composer and Yarn on Ubuntu 22.04.

## Installing Nginx on Ubuntu 22.04

### 1. Update package index:
```bash
sudo apt update
```

### 2. Install Nginx:
```bash
sudo apt install nginx
```

### 3. Start Nginx:
```bash
sudo systemctl start nginx
```

### 4. Enable Nginx to start on boot:
```bash
sudo systemctl enable nginx
```

### 5. Configure firewall (if required):
```bash
sudo ufw allow "Nginx HTTP"
sudo ufw allow "Nginx HTTPS"
sudo ufw reload
```

### 6. Verify Nginx installation:
Open your web browser and enter your server's IP address. You should see the default Nginx welcome page.

### 7. Additional Information:
For detailed information and additional options, see the [DigitalOcean Nginx on Ubuntu 22.04 Guide](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-22-04).

---

## Install Node.js

### 1. Add NodeSource repository:
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
```

### 2. Install Node.js:
```bash
sudo apt install nodejs
```

### 3. Verify installation:
```bash
node -v
npm -v
```

---

## Install Composer

### 1. Update package index:
```bash
sudo apt update
```

### 2. Install necessary tools:
```bash
sudo apt install php-cli unzip curl
```

### 3. Download and install Composer:
```bash
cd ~
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
HASH=$(curl -sS https://composer.github.io/installer.sig)
php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('/tmp/composer-setup.php'); } echo PHP_EOL;"
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
```

### 4. Verify installation:
```bash
composer --version
```

---

## Install Yarn with npm

### 1. Install Yarn (assuming npm is already installed):
```bash
npm install --global yarn
```

### 2. Verify installation:
```bash
yarn --version
```

---

## Install Additional PHP Extensions

### Install php-dom extension:
```bash
sudo apt install php-dom
```

### Verify installation (if necessary):
```bash
php -m | grep dom
```

---

## Common PHP Extensions for Web Development

```bash
# Install commonly needed PHP extensions
sudo apt install php-fpm php-mysql php-curl php-gd php-xml php-mbstring php-zip php-intl php-bcmath

# For specific PHP version (e.g., PHP 8.1)
sudo apt install php8.1-fpm php8.1-mysql php8.1-curl php8.1-gd php8.1-xml php8.1-mbstring php8.1-zip php8.1-intl php8.1-bcmath
```

## Verification Commands

```bash
# Check all installed services
sudo systemctl status nginx
sudo systemctl status php8.1-fpm  # or your PHP version

# Check versions
nginx -v
php -v
node -v
npm -v
composer --version
yarn --version
```
