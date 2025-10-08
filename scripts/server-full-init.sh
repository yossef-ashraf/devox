#!/bin/bash
# ================================
#  LEMP Stack Installer for Ubuntu
# ================================

# ---------- Settings ----------
SERVER_DOMAIN="_"            # Domain name, leave as "_" if not used
PROJECT_NAME="myproject"     # Project name (used for /var/www/ folder)
GIT_REPO_URL=""              # Git repo URL (leave empty if not used)
GIT_BRANCH=""                # Git branch (leave empty for default, e.g., "develop")
SQL_FILE_PATH=""             # Path to SQL file (if exists locally on the server)
DB_NAME="mydb"               # Database name
DB_USER="myuser"             # Database user
DB_PASS="StrongPassword123"  # Database password
PHP_VERSION="8.1"            # PHP version

# Get server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "Installing PHP $PHP_VERSION ..."

# Function to check command success
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Failed: $1"
        echo "⚠️ Continuing to the next step..."
        return 1
    fi
}

echo ">>> Updating system"
sudo apt update -y && sudo apt upgrade -y
check_success "System update"

echo ">>> Installing Nginx"
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
check_success "Nginx installation"

echo ">>> Adding modern PHP repositories (if not exists)"
sudo apt install -y software-properties-common curl
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update -y
check_success "PHP repository addition"

echo ">>> Installing MySQL"
sudo apt install -y mysql-server
sudo systemctl enable mysql
sudo systemctl start mysql
check_success "MySQL installation"

echo ">>> Basic MySQL security"
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASS}'; FLUSH PRIVILEGES;" 2>/dev/null || true
check_success "MySQL root configuration"

echo ">>> Creating database and user"
sudo mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || echo "⚠️ Issue creating database - may already exist"
sudo mysql -uroot -proot -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null || echo "⚠️ Issue creating user - may already exist"
sudo mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;" 2>/dev/null || echo "⚠️ Issue granting privileges"
check_success "Database and user setup"

echo ">>> Installing PHP $PHP_VERSION + common extensions"
sudo apt install -y php${PHP_VERSION}-fpm php${PHP_VERSION}-mysql php${PHP_VERSION}-cli php${PHP_VERSION}-curl php${PHP_VERSION}-gd php${PHP_VERSION}-xml php${PHP_VERSION}-mbstring unzip
check_success "PHP and extensions installation"

echo ">>> Installing Composer"
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer
check_success "Composer installation"

PHP_FPM_SOCK="/var/run/php/php${PHP_VERSION}-fpm.sock"

echo ">>> Creating project folder: /var/www/${PROJECT_NAME}"
sudo mkdir -p /var/www/${PROJECT_NAME}
sudo chown -R $USER:$USER /var/www/${PROJECT_NAME}
sudo chmod -R 755 /var/www/${PROJECT_NAME}
check_success "Project folder creation"

if [ -n "$GIT_REPO_URL" ]; then
    echo ">>> Attempting to clone from $GIT_REPO_URL"
    if [ -n "$GIT_BRANCH" ]; then
        git clone -b $GIT_BRANCH $GIT_REPO_URL /var/www/${PROJECT_NAME} 2>/dev/null || {
            echo "⚠️ Git clone failed, creating default project instead"
            cat <<EOF > /var/www/${PROJECT_NAME}/index.php
<?php
echo "<h1>Welcome to ${PROJECT_NAME}</h1>";
echo "<p>PHP is working! (PHP ${PHP_VERSION})</p>";
echo "<p style='color: orange;'>Note: Git clone failed, using default project</p>";
try {
    \$pdo = new PDO("mysql:host=localhost;dbname=${DB_NAME}", "${DB_USER}", "${DB_PASS}");
    echo "<p style='color: green;'>Database connection: SUCCESS</p>";
} catch (PDOException \$e) {
    echo "<p style='color: red;'>Database connection: FAILED - " . \$e->getMessage() . "</p>";
}
?>
EOF
        }
    else
        git clone $GIT_REPO_URL /var/www/${PROJECT_NAME} 2>/dev/null || {
            echo "⚠️ Git clone failed, creating default project instead"
            cat <<EOF > /var/www/${PROJECT_NAME}/index.php
<?php
echo "<h1>Welcome to ${PROJECT_NAME}</h1>";
echo "<p>PHP is working! (PHP ${PHP_VERSION})</p>";
echo "<p style='color: orange;'>Note: Git clone failed, using default project</p>";
try {
    \$pdo = new PDO("mysql:host=localhost;dbname=${DB_NAME}", "${DB_USER}", "${DB_PASS}");
    echo "<p style='color: green;'>Database connection: SUCCESS</p>";
} catch (PDOException \$e) {
    echo "<p style='color: red;'>Database connection: FAILED - " . \$e->getMessage() . "</p>";
}
?>
EOF
        }
    fi
else
    echo ">>> No Git URL provided, creating default project"
    cat <<EOF > /var/www/${PROJECT_NAME}/index.php
<?php
echo "<h1>Welcome to ${PROJECT_NAME}</h1>";
echo "<p>PHP is working! (PHP ${PHP_VERSION})</p>";
try {
    \$pdo = new PDO("mysql:host=localhost;dbname=${DB_NAME}", "${DB_USER}", "${DB_PASS}");
    echo "<p style='color: green;'>Database connection: SUCCESS</p>";
} catch (PDOException \$e) {
    echo "<p style='color: red;'>Database connection: FAILED - " . \$e->getMessage() . "</p>";
}
?>
EOF
    check_success "Default project creation"
fi

if [ -n "$SQL_FILE_PATH" ] && [ -f "$SQL_FILE_PATH" ]; then
    echo ">>> Importing database from $SQL_FILE_PATH"
    mysql -u${DB_USER} -p${DB_PASS} ${DB_NAME} < $SQL_FILE_PATH 2>/dev/null && {
        check_success "Database import"
    } || {
        echo "⚠️ Failed to import database from $SQL_FILE_PATH"
    }
else
    echo ">>> No SQL file provided for import"
fi

echo ">>> Setting up Nginx for the project"
sudo tee /etc/nginx/sites-available/${PROJECT_NAME} > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    root /var/www/${PROJECT_NAME};
    index index.php index.html index.htm;

    server_name ${SERVER_DOMAIN};

    location / {
        try_files \$uri \$uri/ =404;
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

sudo ln -s /etc/nginx/sites-available/${PROJECT_NAME} /etc/nginx/sites-enabled/
sudo unlink /etc/nginx/sites-enabled/default 2>/dev/null || true
sudo nginx -t
sudo systemctl restart nginx
check_success "Nginx configuration"

echo ">>> Installation completed!"
echo "-----------------------------------"
echo "Project Path: /var/www/${PROJECT_NAME}"
echo "Database Name: ${DB_NAME}"
echo "Database User: ${DB_USER}"
echo "Database Pass: ${DB_PASS}"
echo "MySQL Root Pass: root"
echo "PHP Version: ${PHP_VERSION}"
echo "Server Domain: ${SERVER_DOMAIN}"
echo "Git Repo: ${GIT_REPO_URL:-NONE}"
echo "Git Branch: ${GIT_BRANCH:-DEFAULT}"
echo "SQL File: ${SQL_FILE_PATH:-NONE}"
echo "Your Server IP: ${SERVER_IP}"
echo "Open http://${SERVER_IP} to verify the site is working"
echo "-----------------------------------"

# Display additional network information
echo ">>> Network Information:"
echo "Local IP: ${SERVER_IP}"
echo "All IP addresses:"
ip addr show | grep inet | grep -v inet6 | awk '{print $2}'
echo "-----------------------------------"