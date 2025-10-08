# Nginx Configuration for WordPress with Let's Encrypt SSL

Complete guide for setting up Nginx with WordPress and SSL certificates using Let's Encrypt.

---

## Configuration Files

### Default Nginx Configuration (Port 80)

```nginx
# /etc/nginx/sites-available/wordpress

server {
    listen 80;
    server_name your-server-ip-or-domain;

    root /var/www/html/wordpress;
    index index.php index.html index.htm;

    # WordPress main page location
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # PHP-FPM settings for processing PHP files
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Static files path like images and CSS
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires max;
        log_not_found off;
    }

    # Security improvement against common attacks
    location = /xmlrpc.php {
        deny all;
    }

    # Log settings
    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;
}
```

### Custom Port Configuration (Port 8080)

```nginx
# /etc/nginx/sites-available/wordpress-8080

server {
    listen 8080;
    server_name your-server-ip-or-domain;

    root /var/www/html/wordpress;
    index index.php index.html index.htm;

    # WordPress main page location
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # PHP-FPM settings for processing PHP files
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Static files path like images and CSS
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires max;
        log_not_found off;
    }

    # Security improvement against common attacks
    location = /xmlrpc.php {
        deny all;
    }

    # Log settings
    access_log /var/log/nginx/wordpress-8080_access.log;
    error_log /var/log/nginx/wordpress-8080_error.log;
}
```

---

## Activation Steps

### 1. Enable Default Configuration (Port 80):
```bash
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
nginx -t  # Check configuration validity
systemctl restart nginx  # Restart Nginx
```

### 2. Enable Custom Configuration (Port 8080):
```bash
ln -s /etc/nginx/sites-available/wordpress-8080 /etc/nginx/sites-enabled/
nginx -t  # Check configuration validity
systemctl restart nginx  # Restart Nginx
```

### Note:
- Make sure to modify `server_name` in the files to your IP address or domain name.
- If using a firewall (like `ufw`), allow port 8080:

```bash
sudo ufw allow 8080
sudo ufw reload
```

---

## SSL Setup with Let's Encrypt

### 1. Install Certbot and Nginx Plugin

```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

### 2. Request SSL Certificate

You can request a free SSL certificate using `certbot`:

```bash
sudo certbot --nginx -d your-domain -d www.your-domain
```

*Replace `your-domain` with your actual domain name. If using only an IP address, you'll need to register a domain name.*

### 3. Setup Automatic Certificate Renewal

Let's Encrypt certificates are valid for only 90 days. To renew them automatically, ensure `cron` or `systemd` is set up for automatic renewal:

```bash
sudo certbot renew --dry-run
```

If everything works correctly, `certbot` will automatically renew the certificate when it's close to expiration.

---

## Nginx Configuration with SSL & HTTP/2

### SSL-Enabled Nginx Configuration (Port 443):

```nginx
# /etc/nginx/sites-available/wordpress-ssl

server {
    listen 443 ssl http2;
    server_name your-domain www.your-domain;

    root /var/www/html/wordpress;
    index index.php index.html index.htm;

    # SSL settings
    ssl_certificate /etc/letsencrypt/live/your-domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    
    # Security improvements against attacks like SSL Beast
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # WordPress main page location
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # PHP-FPM settings for processing PHP files
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Static files path like images and CSS
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires max;
        log_not_found off;
    }

    # Security improvement against common attacks
    location = /xmlrpc.php {
        deny all;
    }

    # Log settings
    access_log /var/log/nginx/wordpress_ssl_access.log;
    error_log /var/log/nginx/wordpress_ssl_error.log;
}

# Redirect any HTTP traffic to HTTPS
server {
    listen 80;
    server_name your-domain www.your-domain;

    return 301 https://$host$request_uri;
}
```

### Configuration Explanation:
1. **`listen 443 ssl http2`**: Enable HTTPS and HTTP/2 protocols.
2. **SSL Settings**: Let's Encrypt certificate paths are located in `/etc/letsencrypt/live/your-domain/`.
3. **SSL Security**: Settings to strengthen security using TLSv1.2 and TLSv1.3 protocols.
4. **HTTP to HTTPS**: Redirect any traffic on port 80 to HTTPS.

---

## Final Activation Steps

### 1. Enable New Configuration:

```bash
ln -s /etc/nginx/sites-available/wordpress-ssl /etc/nginx/sites-enabled/
nginx -t  # Check configuration validity
systemctl restart nginx  # Restart Nginx
```

### 2. Allow Port 443 (HTTPS) in Firewall:

```bash
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'
```

---

## Notes:
- **HTTP/2**: Helps speed up page loading by improving communication between browser and server.
- **SSL**: Make sure to monitor certificate renewal regularly.
- **Security**: The configuration includes protection against common WordPress attacks.

## Troubleshooting:
- **Configuration Test**: Always run `nginx -t` before restarting
- **Log Files**: Check `/var/log/nginx/` for error logs
- **Certificate Issues**: Use `sudo certbot certificates` to check certificate status
- **Firewall**: Ensure ports 80 and 443 are open