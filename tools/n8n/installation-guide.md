# n8n Installation and Configuration Guide

Complete documentation for installing and configuring n8n on Ubuntu with npm + systemd service + nginx + SSL.

---

## 📘 Installing and Configuring n8n on Ubuntu with Domain and SSL

### Overview

This guide covers the complete installation of n8n on Ubuntu server from start to finish, including domain configuration (n8n.cloudhosta.com), systemd service setup for automatic startup, and nginx reverse proxy with SSL configuration.

---

## 🔹 1. System Update

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 🔹 2. Install Requirements

```bash
# Install Node.js (LTS) and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs build-essential

# Verify versions
node -v
npm -v
```

---

## 🔹 3. Install n8n

```bash
sudo npm install -g n8n
```

n8n will be installed globally at `/usr/bin/n8n`.

---

## 🔹 4. Create systemd Service

To ensure n8n starts automatically after every reboot:

```bash
sudo nano /etc/systemd/system/n8n.service
```

File content:

```ini
[Unit]
Description=n8n
After=network.target

[Service]
ExecStart=/usr/bin/n8n
Restart=always
User=root
Environment=PATH=/usr/bin:/usr/local/bin
WorkingDirectory=/root

# Environment settings
Environment=N8N_HOST=n8n.cloudhosta.com
Environment=N8N_PORT=5678
Environment=N8N_PROTOCOL=https
Environment=WEBHOOK_URL=https://n8n.cloudhosta.com/
Environment=N8N_LISTEN_ADDRESS=0.0.0.0

[Install]
WantedBy=multi-user.target
```

Enable the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable n8n
sudo systemctl start n8n
sudo systemctl status n8n
```

---

## 🔹 5. Setup Nginx with SSL

Create SSL certificates folder:

```bash
sudo mkdir -p /etc/ssl/n8n
```

Create Self-Signed certificate (for testing):

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/n8n/selfsigned.key \
-out /etc/ssl/n8n/selfsigned.crt \
-subj "/CN=n8n.cloudhosta.com/O=n8n/C=EG"
```

---

## 🔹 6. Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/n8n.conf
```

File content:

```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 443 ssl http2;
    server_name n8n.cloudhosta.com;
    
    ssl_certificate /etc/ssl/n8n/selfsigned.crt;
    ssl_certificate_key /etc/ssl/n8n/selfsigned.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    proxy_connect_timeout       300s;
    proxy_send_timeout          300s;
    proxy_read_timeout          300s;
    send_timeout                300s;

    proxy_buffer_size          128k;
    proxy_buffers              4 256k;
    proxy_busy_buffers_size    256k;

    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;

        proxy_cache_bypass $http_upgrade;
        proxy_no_cache $http_upgrade;

        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/n8n.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## 🔹 7. Access n8n

Open your browser and navigate to:

```
https://n8n.cloudhosta.com
```

---

## 🔹 8. Additional Notes

### Let's Encrypt SSL (Production Ready)

For production use with Let's Encrypt instead of self-signed:

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d n8n.cloudhosta.com
```

### Service Logs

View service logs:

```bash
journalctl -u n8n -f
```

---

## ✅ Result

- ✅ n8n runs automatically via systemd
- ✅ Connected to your domain: n8n.cloudhosta.com
- ✅ Running behind nginx reverse proxy with SSL
- ✅ Production-ready configuration

---

## 🔧 Troubleshooting

### Common Issues:
- **Service not starting**: Check logs with `journalctl -u n8n -f`
- **Domain not accessible**: Verify DNS settings and firewall
- **SSL certificate errors**: Use Let's Encrypt for production domains
- **Port conflicts**: Ensure port 5678 is available

### Useful Commands:
```bash
# Check service status
sudo systemctl status n8n

# Restart service
sudo systemctl restart n8n

# View real-time logs
journalctl -u n8n -f

# Test nginx configuration
sudo nginx -t
```