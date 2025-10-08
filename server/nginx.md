# Nginx Configuration Guide

## Nginx Setup for WordPress

### Basic Configuration File (Port 80)

```nginx
# /etc/nginx/sites-available/wordpress
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    root /var/www/html/wordpress;
    index index.php index.html index.htm;

    # WordPress settings
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # PHP file processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Static file optimization
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        log_not_found off;
    }

    # Protection from xmlrpc attacks
    location = /xmlrpc.php {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Protect system files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Logging
    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;
}
```

### SSL Setup with Let's Encrypt

```nginx
# /etc/nginx/sites-available/wordpress-ssl
server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;

    root /var/www/html/wordpress;
    index index.php index.html index.htm;

    # SSL settings
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # SSL optimization
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;

    # Same settings as basic configuration...
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    return 301 https://$host$request_uri;
}
```

## Nginx Management Commands

```bash
# Test configuration validity
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Reload configuration without stopping service
sudo systemctl reload nginx

# Enable site
sudo ln -s /etc/nginx/sites-available/site-name /etc/nginx/sites-enabled/

# Disable site
sudo rm /etc/nginx/sites-enabled/site-name

# Check Nginx status
sudo systemctl status nginx

# View error logs
sudo tail -f /var/log/nginx/error.log

# View access logs
sudo tail -f /var/log/nginx/access.log
```

## Performance Optimization Settings

```nginx
# In /etc/nginx/nginx.conf
http {
    # File compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Connection optimization
    keepalive_timeout 65;
    keepalive_requests 100;

    # Upload file size
    client_max_body_size 64M;

    # Buffer sizes
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 4k;
}
```