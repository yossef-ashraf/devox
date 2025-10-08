#!/bin/bash
# ================================
#  LEMN Stack Installer for Ubuntu (Node.js)
# ================================

# ---------- Settings ----------
SERVER_DOMAIN="_"            # Domain name, leave as "_" if not used
PROJECT_NAME="myproject"     # Project name (used for /var/www/ folder)
GIT_REPO_URL=""              # Git repo URL (leave empty if not used)
GIT_BRANCH=""                # Git branch (leave empty for default, e.g., "develop")
SQL_FILE_PATH=""             # Path to SQL/JSON file (if exists locally on the server)
DB_TYPE="mysql"              # Database type: "mysql" or "mongodb"
DB_NAME="mydb"               # Database name
DB_USER="myuser"             # Database user
DB_PASS="test"  # Database password
NODE_VERSION="22"            # Node.js version (LTS)
APP_PORT="3000"              # Port for Node.js app

# Get server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "Installing Node.js $NODE_VERSION with $DB_TYPE database..."

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
sudo apt install -y nodejs
check_success "Node.js installation"

node -v
npm -v

echo ">>> Installing PM2 globally"
sudo npm install -g pm2
check_success "PM2 installation"

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
    echo ">>> Attempting to clone from $GIT_REPO_URL"
    if [ -n "$GIT_BRANCH" ]; then
        git clone -b $GIT_BRANCH $GIT_REPO_URL . 2>/dev/null || {
            echo "⚠️ Git clone failed, creating default Node.js project instead"
            create_default_node_app
        }
    else
        git clone $GIT_REPO_URL . 2>/dev/null || {
            echo "⚠️ Git clone failed, creating default Node.js project instead"
            create_default_node_app
        }
    fi
    echo ">>> Running npm install"
    npm install 2>/dev/null || echo "⚠️ npm install may have issues, check manually"
else
    echo ">>> No Git URL provided, creating default Node.js project"
    create_default_node_app
fi

# Function to create default Node.js app
create_default_node_app() {
    cat <<EOF > package.json
{
  "name": "${PROJECT_NAME}",
  "version": "1.0.0",
  "description": "Default Node.js app",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "mysql2": "^3.0.0",
    "mongodb": "^6.0.0"
  }
}
EOF

    npm install

    cat <<EOF > app.js
const express = require('express');
const app = express();
const port = process.env.PORT || ${APP_PORT};

app.use(express.json());
app.use(express.static('public'));

app.get('/', async (req, res) => {
    let dbStatus = 'Not tested';
    try {
        if ('${DB_TYPE}' === 'mysql') {
            const mysql = require('mysql2/promise');
            const connection = await mysql.createConnection({
                host: 'localhost',
                user: '${DB_USER}',
                password: '${DB_PASS}',
                database: '${DB_NAME}'
            });
            await connection.end();
            dbStatus = 'SUCCESS';
        } else if ('${DB_TYPE}' === 'mongodb') {
            const { MongoClient } = require('mongodb');
            const client = new MongoClient('mongodb://localhost:27017', {
                auth: { username: '${DB_USER}', password: '${DB_PASS}' }
            });
            await client.connect();
            await client.db('${DB_NAME}').command({ ping: 1 });
            await client.close();
            dbStatus = 'SUCCESS';
        }
    } catch (err) {
        dbStatus = 'FAILED: ' + err.message;
    }
    res.send(\`
        <h1>Welcome to ${PROJECT_NAME} (Node.js)</h1>
        <p>Node.js is working! (v\${process.version})</p>
        <p>Database (${DB_TYPE}) connection: <span style="color: \${dbStatus === 'SUCCESS' ? 'green' : 'red'};">\${dbStatus}</span></p>
        <p>Server IP: ${SERVER_IP}</p>
    \`);
});

app.listen(port, '0.0.0.0', () => {
    console.log('App listening on port \${port}');
});
EOF

    mkdir -p public
    check_success "Default Node.js app creation"
}

echo ">>> Starting Node.js app with PM2"
pm2 start npm --name "${PROJECT_NAME}" -- run start
pm2 save
pm2 startup
check_success "PM2 startup"

echo ">>> Setting up Nginx for the project"
sudo tee /etc/nginx/sites-available/${PROJECT_NAME} > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    root /var/www/${PROJECT_NAME};
    index index.html index.htm;

    server_name ${SERVER_DOMAIN};

    location / {
        proxy_pass http://localhost:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
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
echo "Database Type: ${DB_TYPE}"
echo "Database Name: ${DB_NAME}"
echo "Database User: ${DB_USER}"
echo "Database Pass: ${DB_PASS}"
echo "MySQL/MongoDB Root Pass: root"
echo "Node.js Version: ${NODE_VERSION}"
echo "App Port: ${APP_PORT}"
echo "Server Domain: ${SERVER_DOMAIN}"
echo "Git Repo: ${GIT_REPO_URL:-NONE}"
echo "Git Branch: ${GIT_BRANCH:-DEFAULT}"
echo "SQL/JSON File: ${SQL_FILE_PATH:-NONE}"
echo "Your Server IP: ${SERVER_IP}"
echo "Open http://${SERVER_IP} to verify the site is working"
echo "-----------------------------------"
echo "PM2 Commands: pm2 status, pm2 logs ${PROJECT_NAME}, pm2 restart ${PROJECT_NAME}"

# Display additional network information
echo ">>> Network Information:"
echo "Local IP: ${SERVER_IP}"
echo "All IP addresses:"
ip addr show | grep inet | grep -v inet6 | awk '{print $2}'
echo "-----------------------------------"