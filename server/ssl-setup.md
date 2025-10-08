# SSL Certificate Setup Guide

## SSL Setup with Let's Encrypt

### Install Certbot

```bash
# Update system
sudo apt update

# Install Certbot and Nginx plugin
sudo apt install certbot python3-certbot-nginx

# Verify installation
certbot --version
```

### Obtain SSL Certificate

```bash
# Request SSL certificate for single domain
sudo certbot --nginx -d your-domain.com

# Request certificate for multiple domains
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Request certificate without automatically modifying Nginx config
sudo certbot certonly --nginx -d your-domain.com
```

### Certificate Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Renew all certificates
sudo certbot renew

# Renew specific certificate
sudo certbot renew --cert-name your-domain.com
```

### Setup Automatic Renewal

```bash
# Add cron job for automatic renewal
sudo crontab -e

# Add this line for daily renewal at 2:30 AM
30 2 * * * /usr/bin/certbot renew --quiet
```

## Manual SSL Setup (Paid Certificate)

### Create Certificate Signing Request (CSR)

```bash
# Create private key and CSR
openssl req -new -newkey rsa:2048 -nodes -keyout server.key -out server.csr

# Create CSR from existing key
openssl req -new -key existing-private.key -out server.csr
```

### Required Information for CSR

```
Country Name (2 letter code): EG
State or Province Name: Cairo
City or Locality Name: Cairo
Organization Name: Your Company
Organizational Unit Name: IT Department
Common Name: your-domain.com
Email Address: admin@your-domain.com
Challenge password: [leave blank]
Optional company name: [leave blank]
```

### Install Certificate

```bash
# Combine main certificate with intermediate certificates
cat your-domain.crt intermediate.crt > bundle.crt

# Copy files to SSL directory
sudo cp bundle.crt /etc/ssl/certs/
sudo cp server.key /etc/ssl/private/

# Set permissions
sudo chmod 644 /etc/ssl/certs/bundle.crt
sudo chmod 600 /etc/ssl/private/server.key
```

### Configure Nginx for Manual Certificate

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/ssl/certs/bundle.crt;
    ssl_certificate_key /etc/ssl/private/server.key;

    # Additional configurations...
}
```

## Certificate Verification

```bash
# Check certificate expiration date
openssl x509 -in /etc/ssl/certs/bundle.crt -text -noout | grep "Not After"

# Check certificate online
openssl s_client -connect your-domain.com:443 -servername your-domain.com

# Check certificate details
openssl x509 -in /etc/ssl/certs/bundle.crt -text -noout
```

## Troubleshooting

### Common Issues and Solutions

```bash
# Error: "SSL certificate problem"
# Check file paths in Nginx configuration

# Error: "Mixed content"
# Ensure all links use HTTPS

# Error: "Certificate chain incomplete"
# Ensure intermediate certificates are properly merged

# Check error logs
sudo tail -f /var/log/nginx/error.log
```

### Useful SSL Testing Tools

- [SSL Labs Test](https://www.ssllabs.com/ssltest/)
- [SSL Checker](https://www.sslshopper.com/ssl-checker.html)
- [Why No Padlock](https://www.whynopadlock.com/)

## Security Best Practices

```nginx
# Secure SSL settings in Nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

# Security headers
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```