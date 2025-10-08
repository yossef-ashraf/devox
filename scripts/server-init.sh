#!/bin/bash
# ================================
#  LEMP Stack Installer for Ubuntu
# ================================

# ---------- Settings ----------
PROJECT_NAME="name"
DB_NAME="db"
DB_USER="user"
DB_PASS="test"
PHP_VERSION="8.1" 

# Get server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "Installing PHP $PHP_VERSION ..."

echo ">>> Updating system"
sudo apt update -y && sudo apt upgrade -y

echo ">>> Installing Nginx"
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

echo ">>> Adding modern PHP repositories (if not exists)"
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update -y

echo ">>> Installing MySQL"
sudo apt install -y mysql-server
sudo systemctl enable mysql
sudo systemctl start mysql

echo ">>> Basic MySQL security"
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root'; FLUSH PRIVILEGES;"

echo ">>> Creating database and user"
sudo mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -uroot -proot -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

echo ">>> Installing PHP $PHP_VERSION + common extensions"
sudo apt install -y php${PHP_VERSION}-fpm php${PHP_VERSION}-mysql php${PHP_VERSION}-cli php${PHP_VERSION}-curl php${PHP_VERSION}-gd php${PHP_VERSION}-xml php${PHP_VERSION}-mbstring unzip

PHP_FPM_SOCK="/var/run/php/php${PHP_VERSION}-fpm.sock"

echo ">>> Creating project folder: /var/www/${PROJECT_NAME}"
sudo mkdir -p /var/www/${PROJECT_NAME}
sudo chown -R $USER:$USER /var/www/${PROJECT_NAME}
sudo chmod -R 755 /var/www/${PROJECT_NAME}

echo ">>> Creating index.php file for the project"
cat <<EOF > /var/www/${PROJECT_NAME}/index.php
<?php
echo "<h1>Welcome to ${PROJECT_NAME}</h1>";
echo "<p>PHP is working! (PHP ${PHP_VERSION})</p>";
echo "<p>Server IP: ${SERVER_IP}</p>";

// Database connection test
try {
    \$pdo = new PDO("mysql:host=localhost;dbname=${DB_NAME}", "${DB_USER}", "${DB_PASS}");
    echo "<p style='color: green;'>Database connection: SUCCESS</p>";
} catch (PDOException \$e) {
    echo "<p style='color: red;'>Database connection: FAILED - " . \$e->getMessage() . "</p>";
}
?>
EOF

echo ">>> Setting up Nginx for the project"
sudo tee /etc/nginx/sites-available/${PROJECT_NAME} > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    root /var/www/${PROJECT_NAME};
    index index.php index.html index.htm;

    server_name _;

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
sudo unlink /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

echo ">>> Installation completed!"
echo "-----------------------------------"
echo "Project Path: /var/www/${PROJECT_NAME}"
echo "Database Name: ${DB_NAME}"
echo "Database User: ${DB_USER}"
echo "Database Pass: ${DB_PASS}"
echo "MySQL Root Pass: root"
echo "PHP Version: ${PHP_VERSION}"
echo "Your Server IP: ${SERVER_IP}"
echo "Open http://${SERVER_IP} to verify the site is working"
echo "-----------------------------------"

# Display additional network information
echo ">>> Network Information:"
echo "Local IP: ${SERVER_IP}"
echo "All IP addresses:"
ip addr show | grep inet | grep -v inet6 | awk '{print $2}'
echo "-----------------------------------"