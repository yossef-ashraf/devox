#!/bin/bash
# ================================
#  n8n Installer for Ubuntu
# ================================

# ---------- Settings ----------
SERVER_DOMAIN="_"            # Domain name, e.g., "n8n.example.com", leave as "_" if not used
PROJECT_NAME="n8n"           # Project name (used for /var/www/ folder)
GIT_REPO_URL=""              # Git repo URL for custom n8n (leave empty to use npm)
GIT_BRANCH=""                # Git branch (leave empty for default, e.g., "develop")
SQL_FILE_PATH=""             # Path to SQL/JSON file (if exists locally on the server)
DB_TYPE="mysql"              # Database type: "mysql" or "mongodb"
DB_NAME="n8n_db"             # Database name
DB_USER="n8n_user"           # Database user
DB_PASS="test"  # Database password
NODE_VERSION="22"            # Node.js version (LTS)
N8N_PORT="5678"              # Port for n8n
SSL_TYPE="letsencrypt"       # SSL type: "letsencrypt" or "selfsigned"

# Get server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "Installing n8n with Node.js $NODE_VERSION and $DB_TYPE database..."

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

echo ">>> Installing Node.js $NODE_VERSION"
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
sudo apt install -y nodejs build-essential
check_success "Node.js installation"

node -v
npm -v

if [ "$DB_TYPE" = "mysql" ]; then
    echo ">>> Installing MySQL"
    sudo apt install -y mysql-server
    sudo systemctl enable mysql
    sudo systemctl start mysql
    check_success "MySQL installation"

    echo ">>> Basic MySQL security"
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root'; FLUSH PRIVILEGES;" 2>/dev/null || true
    check_success "MySQL root configuration"

    echo ">>> Creating MySQL database and user"
    sudo mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || echo "⚠️ Issue creating database - may already exist"
    sudo mysql -uroot -proot -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null || echo "⚠️ Issue creating user - may already exist"
    sudo mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;" 2>/dev/null || echo "⚠️ Issue granting privileges"
    check_success "MySQL database and user setup"

    if [ -n "$SQL_FILE_PATH" ] && [ -f "$SQL_FILE_PATH" ]; then
        echo ">>> Importing MySQL database from $SQL_FILE_PATH"
        mysql -u${DB_USER} -p${DB_PASS} ${DB_NAME} < $SQL_FILE_PATH 2>/dev/null && {
            check_success "MySQL database import"
        } || {
            echo "⚠️ Failed to import MySQL database from $SQL_FILE_PATH"
        }
    else
        echo ">>> No SQL file provided for MySQL import"
    fi
elif [ "$DB_TYPE" = "mongodb" ]; then
    echo ">>> Installing MongoDB"
    sudo apt install -y gnupg curl
    curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    sudo apt update -y
    sudo apt install -y mongodb-org
    check_success "MongoDB installation"

    sudo systemctl enable mongod
    sudo systemctl start mongod
    check_success "MongoDB service startup"

    echo ">>> Creating MongoDB database and user"
    mongo --eval "db.getSiblingDB('admin').createUser({user: '${DB_USER}', pwd: '${DB_PASS}', roles: [{role: 'readWrite', db: '${DB_NAME}'}]})" 2>/dev/null || echo "⚠️ Issue creating MongoDB user - may already exist"
    check_success "MongoDB database and user setup"

    if [ -n "$SQL_FILE_PATH" ] && [ -f "$SQL_FILE_PATH" ]; then
        echo ">>> Importing MongoDB database from $SQL_FILE_PATH"
        mongoimport --authenticationDatabase admin -u ${DB_USER} -p ${DB_PASS} -d ${DB_NAME} -c data --file $SQL_FILE_PATH 2>/dev/null && {
            check_success "MongoDB database import"
        } || {
            echo "⚠️ Failed to import MongoDB database from $SQL_FILE_PATH"
        }
    else
        echo ">>> No JSON file provided for MongoDB import"
    fi
else
    echo "❌ Invalid DB_TYPE: $DB_TYPE. Use 'mysql' or 'mongodb'"
    exit 1
fi

echo ">>> Creating project folder: /var/www/${PROJECT_NAME}"
sudo mkdir -p /var/www/${PROJECT_NAME}
sudo chown -R $USER:$USER /var/www/${PROJECT_NAME}
sudo chmod -R 755 /var/www/${PROJECT_NAME}
check_success "Project folder creation"

cd /var/www/${PROJECT_NAME}

if [ -n "$GIT_REPO_URL" ]; then
    echo ">>> Attempting to clone n8n from $GIT_REPO_URL"
    if [ -n "$GIT_BRANCH" ]; then
        git clone -b $GIT_BRANCH $GIT_REPO_URL . 2>/dev/null || {
            echo "⚠️ Git clone failed, installing n8n via npm instead"
            sudo npm install -g n8n
        }
    else
        git clone $GIT_REPO_URL . 2>/dev/null || {
            echo "⚠️ Git clone failed, installing n8n via npm instead"
            sudo npm install -g n8n
        }
    fi
    echo ">>> Running npm install for custom n8n"
    npm install 2>/dev/null || echo "⚠️ npm install may have issues, check manually"
else
    echo ">>> No Git URL provided, installing n8n via npm"
    sudo npm install -g n8n
    check_success "n8n installation via npm"
fi

echo ">>> Creating systemd service for n8n"
sudo tee /etc/systemd/system/n8n.service > /dev/null <<EOF
[Unit]
Description=n8n Workflow Automation
After=network.target

[Service]
ExecStart=/usr/bin/n8n
Restart=always
User=root
Environment=PATH=/usr/bin:/usr/local/bin
WorkingDirectory=/var/www/${PROJECT_NAME}

# Environment settings for n8n
Environment=N8N_HOST=${SERVER_DOMAIN}
Environment=N8N_PORT=${N8N_PORT}
Environment=N8N_PROTOCOL=https
Environment=WEBHOOK_URL=https://${SERVER_DOMAIN}/
Environment=N8N_LISTEN_ADDRESS=0.0.0.0
Environment=DB_TYPE=${DB_TYPE}
EOF

if [ "$DB_TYPE" = "mysql" ]; then
    echo "Environment=DB_MYSQLDB_HOST=localhost" >> /etc/systemd/system/n8n.service
    echo "Environment=DB_MYSQLDB_PORT=3306" >> /etc/systemd/system/n8n.service
    echo "Environment=DB_MYSQLDB_DATABASE=${DB_NAME}" >> /etc/systemd/system/n8n.service
    echo "Environment=DB_MYSQLDB_USER=${DB_USER}" >> /etc/systemd/system/n8n.service
    echo "Environment=DB_MYSQLDB_PASSWORD=${DB_PASS}" >> /etc/systemd/system/n8n.service
elif [ "$DB_TYPE" = "mongodb" ]; then
    echo "Environment=DB_MONGODB_CONNECTION_URL=mongodb://${DB_USER}:${DB_PASS}@localhost:27017/${DB_NAME}" >> /etc/systemd/system/n8n.service
fi

sudo systemctl daemon-reload
sudo systemctl enable n8n
sudo systemctl start n8n
check_success "n8n systemd service setup"
sudo systemctl status n8n

echo ">>> Setting up SSL"
sudo mkdir -p /etc/ssl/n8n

if [ "$SSL_TYPE" = "letsencrypt" ] && [ "$SERVER_DOMAIN" != "_" ]; then
    echo ">>> Installing Certbot for Let's Encrypt"
    sudo apt install -y certbot python3-certbot-nginx
    check_success "Certbot installation"

    echo ">>> Obtaining Let's Encrypt SSL certificate"
    sudo certbot --nginx -d ${SERVER_DOMAIN} --non-interactive --agree-tos --email admin@${SERVER_DOMAIN} 2>/dev/null || {
        echo "⚠️ Failed to obtain Let's Encrypt certificate, falling back to self-signed"
        create_self_signed_ssl
    }
else
    echo ">>> Creating self-signed SSL certificate"
    create_self_signed_ssl
fi

# Function to create self-signed SSL certificate
create_self_signed_ssl() {
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/n8n/selfsigned.key \
        -out /etc/ssl/n8n/selfsigned.crt \
        -subj "/CN=${SERVER_DOMAIN}/O=n8n/C=EG" 2>/dev/null
    check_success "Self-signed SSL certificate creation"
}

echo ">>> Setting up Nginx for n8n"
sudo tee /etc/nginx/sites-available/n8n > /dev/null <<EOF
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${SERVER_DOMAIN};

    ssl_certificate /etc/ssl/n8n/selfsigned.crt;
    ssl_certificate_key /etc/ssl/n8n/selfsigned.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://localhost:${N8N_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name ${SERVER_DOMAIN};
    return 301 https://\$host\$request_uri;
}
EOF

if [ "$SSL_TYPE" = "letsencrypt" ] && [ -f "/etc/letsencrypt/live/${SERVER_DOMAIN}/fullchain.pem" ]; then
    sudo sed -i "s|/etc/ssl/n8n/selfsigned.crt|/etc/letsencrypt/live/${SERVER_DOMAIN}/fullchain.pem|" /etc/nginx/sites-available/n8n
    sudo sed -i "s|/etc/ssl/n8n/selfsigned.key|/etc/letsencrypt/live/${SERVER_DOMAIN}/privkey.pem|" /etc/nginx/sites-available/n8n
fi

sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo unlink /etc/nginx/sites-enabled/default 2>/dev/null || true
sudo nginx -t
sudo systemctl restart nginx
check_success "Nginx configuration"

echo ">>> Installation completed!"
echo "-----------------------------------"
echo "Project Path: /var/www/${PROJECT_NAME}"
echo "Database Type: ${DB_TYPE}"
echo "Database Name: ${DB_NAME}"
echo "Database User: ${DB_USER}"
echo "Database Pass: ${DB_PASS}"
echo "MySQL/MongoDB Root Pass: root"
echo "Node.js Version: ${NODE_VERSION}"
echo "n8n Port: ${N8N_PORT}"
echo "Server Domain: ${SERVER_DOMAIN}"
echo "Git Repo: ${GIT_REPO_URL:-NONE}"
echo "Git Branch: ${GIT_BRANCH:-DEFAULT}"
echo "SQL/JSON File: ${SQL_FILE_PATH:-NONE}"
echo "Your Server IP: ${SERVER_IP}"
echo "Open https://${SERVER_DOMAIN:-$SERVER_IP} to access n8n"
echo "-----------------------------------"
echo "Logs: journalctl -u n8n -f"

# Display additional network information
echo ">>> Network Information:"
echo "Local IP: ${SERVER_IP}"
echo "All IP addresses:"
ip addr show | grep inet | grep -v inet6 | awk '{print $2}'
echo "-----------------------------------"