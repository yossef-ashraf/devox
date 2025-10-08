#!/bin/bash
# ===========================================
#        LEMP Auto Setup for Ubuntu
# ===========================================

# General Settings
SERVER_DOMAIN="_"            
PROJECT_NAME="pro"     
ZIP_FILE_PATH="/var/www/data/zip.zip"             
SQL_FILE_PATH="/var/www/data/db.sql"          

DB_NAME="db"
DB_USER="user"
DB_PASS="test"

PHP_VERSION="8.2"            

# ===========================================
echo ">>> Starting installation with PHP $PHP_VERSION ..."

check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Failed: $1"
        echo "⚠️  Continuing to next command..."
        return 1
    fi
}

# System Update
echo ">>> Updating system..."
sudo apt update -y && sudo apt upgrade -y
check_success "System update"

# Install Nginx
echo ">>> Installing Nginx..."
sudo apt install -y nginx
check_success "Nginx installation"

sudo systemctl enable nginx
sudo systemctl start nginx
check_success "Nginx service start"

# Add PHP Repositories
echo ">>> Adding PHP repositories..."
sudo apt install -y software-properties-common curl unzip git composer
check_success "Utility tools installation"

sudo add-apt-repository ppa:ondrej/php -y
check_success "PHP repository addition"

sudo apt update -y
check_success "Package list update"

# Install MySQL
echo ">>> Installing MySQL..."
sudo apt install -y mysql-server
check_success "MySQL installation"

sudo systemctl enable mysql
sudo systemctl start mysql
check_success "MySQL service start"

echo ">>> Setting up database..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASS}'; FLUSH PRIVILEGES;" 2>/dev/null || true

sudo mysql -uroot -p${DB_PASS} -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || echo "⚠️  Database creation issue - might already exist"

sudo mysql -uroot -p${DB_PASS} -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null || echo "⚠️  User creation issue - might already exist"

sudo mysql -uroot -p${DB_PASS} -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;" 2>/dev/null || echo "⚠️  Privileges assignment issue"

# Install PHP
echo ">>> Installing PHP $PHP_VERSION..."
sudo apt install -y php${PHP_VERSION}-fpm php${PHP_VERSION}-mysql php${PHP_VERSION}-cli php${PHP_VERSION}-curl php${PHP_VERSION}-gd php${PHP_VERSION}-xml php${PHP_VERSION}-mbstring php${PHP_VERSION}-zip unzip
check_success "PHP and extensions installation"

PHP_FPM_SOCK="/var/run/php/php${PHP_VERSION}-fpm.sock"

# Project Setup
echo ">>> Creating project folder: /var/www/${PROJECT_NAME}"
sudo mkdir -p /var/www/${PROJECT_NAME}
sudo chown -R $USER:$USER /var/www/${PROJECT_NAME}
sudo chmod -R 755 /var/www/${PROJECT_NAME}
check_success "Project folder creation"

# Import from ZIP file if exists
if [ -n "$ZIP_FILE_PATH" ] && [ -f "$ZIP_FILE_PATH" ]; then
    echo ">>> Extracting ZIP file from $ZIP_FILE_PATH"
    
    TEMP_DIR="/tmp/project_extract_$$"
    mkdir -p $TEMP_DIR
    
    if unzip -q "$ZIP_FILE_PATH" -d $TEMP_DIR; then
        cp -r $TEMP_DIR/* /var/www/${PROJECT_NAME}/ 2>/dev/null || true
        cp -r $TEMP_DIR/.* /var/www/${PROJECT_NAME}/ 2>/dev/null 2>&1 || true
        
        rm -rf $TEMP_DIR
        
        check_success "ZIP file extraction"
        echo "✅ Project imported from $ZIP_FILE_PATH successfully"
    else
        echo "❌ Failed to extract ZIP file"
        rm -rf $TEMP_DIR
        cat <<EOF > /var/www/${PROJECT_NAME}/index.php
<?php
echo "<h1>Welcome to ${PROJECT_NAME}</h1>";
echo "<p>PHP is working! (PHP ${PHP_VERSION})</p>";
echo "<p style='color: orange;'>Note: ZIP extraction failed, using default project</p>";
EOF
    fi
else
    echo ">>> No ZIP file, creating default project..."
    cat <<EOF > /var/www/${PROJECT_NAME}/index.php
<?php
echo "<h1>Welcome to ${PROJECT_NAME}</h1>";
echo "<p>PHP is working! (PHP ${PHP_VERSION})</p>";
echo "<p>Server Time: " . date('Y-m-d H:i:s') . "</p>";
EOF
    check_success "Default project creation"
fi

# Import database if SQL file exists
if [ -n "$SQL_FILE_PATH" ] && [ -f "$SQL_FILE_PATH" ]; then
    echo ">>> Importing database from $SQL_FILE_PATH"
    
    if mysql -u${DB_USER} -p${DB_PASS} ${DB_NAME} < "$SQL_FILE_PATH" 2>/dev/null; then
        check_success "Database import"
    else
        echo "⚠️  Trying with root password..."
        if mysql -uroot -proot ${DB_NAME} < "$SQL_FILE_PATH" 2>/dev/null; then
            check_success "Database import using root"
        else
            echo "❌ Failed to import database from $SQL_FILE_PATH"
            echo "⚠️  Check passwords and database existence"
        fi
    fi
else
    echo ">>> No SQL file to import"
fi

# Nginx Configuration
echo ">>> Configuring Nginx for project..."

PROJECT_ROOT="/var/www/${PROJECT_NAME}"

sudo tee /etc/nginx/sites-available/${PROJECT_NAME} > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    root ${PROJECT_ROOT};
    index index.php index.html index.htm;

    server_name ${SERVER_DOMAIN};

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_FPM_SOCK};
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/${PROJECT_NAME} /etc/nginx/sites-enabled/ 2>/dev/null || echo "⚠️  Nginx link creation issue"
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || echo "⚠️  Default site removal issue"

echo ">>> Testing Nginx configuration..."
sudo nginx -t 2>/dev/null && {
    sudo systemctl restart nginx
    check_success "Nginx configuration"
} || {
    echo "❌ Nginx configuration test failed, check settings manually"
}

# Final Results
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "==========================================="
echo "            ✅ Installation Complete!      "
echo "==========================================="
echo "📁 Project Path: /var/www/${PROJECT_NAME}"
echo "🗄️  Database Name: ${DB_NAME}"
echo "👤 Database User: ${DB_USER}"
echo "🔐 Database Pass: ${DB_PASS}"
echo "⚡ PHP Version: ${PHP_VERSION}"
echo "📦 ZIP File: ${ZIP_FILE_PATH:-NONE}"
echo "📊 SQL File: ${SQL_FILE_PATH:-NONE}"
echo ""
echo "🌍 Open http://${SERVER_IP} to verify the site"
echo ""
echo "⚠️  If there are errors, check above messages for details"
echo "==========================================="

# Service Status Check
echo ""
echo ">>> Final service status check:"
sudo systemctl is-active --quiet nginx && echo "✅ Nginx is running" || echo "❌ Nginx is NOT running"
sudo systemctl is-active --quiet mysql && echo "✅ MySQL is running" || echo "❌ MySQL is NOT running"
sudo systemctl is-active --quiet php${PHP_VERSION}-fpm && echo "✅ PHP-FPM is running" || echo "❌ PHP-FPM is NOT running"