# Laravel Reverb WebSocket Setup Guide (Production)

This document records every step taken to fix and configure Laravel Reverb WebSockets
on the Ecral APIs server, including the commands run, their results, and the final
Nginx configuration. Use it to replicate the setup on a different server.

> **Placeholders to change per server** are listed at the bottom in the
> [Values to change on a new server](#values-to-change-on-a-new-server) section.

---

## Problem summary

The frontend failed to open a WebSocket connection:

```
WebSocket connection to 'wss://apis.ecral.com:8087/socket.io/?appKey=ecral-key&...' failed
Error: connect ECONNREFUSED 167.233.124.125:8087
```

**Root cause:** Reverb was not running on the server, and there was no Nginx reverse
proxy listening on port 8087. Nothing was bound to the port, so every connection was
refused at the TCP level.

---

## Diagnosis (how we confirmed the cause)

### 1. Check whether Reverb is running

```bash
ps aux | grep reverb
sudo supervisorctl status
```

Result: no Reverb process. Supervisor only had `ecral-scheduler` and `ecral-worker`
registered — no Reverb program existed.

### 2. Check what is listening on the relevant ports

```bash
sudo ss -tlnp | grep -E '8080|8087'
```

Result: **empty** — nothing was listening on 8080 or 8087.

### 3. Confirm from inside the server

```bash
curl -v http://localhost:8080/app/ecral-key
```

Result: `Connection refused` — proving Reverb was down (not a firewall/proxy issue).

---

## Fix Part 1 — Run Reverb permanently under Supervisor

### 1. Verify Reverb starts cleanly (manual test)

```bash
cd /var/www/ecral
php artisan reverb:start --debug
```

Expected output:

```
INFO  Starting server on 0.0.0.0:8080 (localhost).
```

> Note: running it manually ties it to your SSH session — it stops when you close the
> terminal. That is why it must run under Supervisor (next step). Press Ctrl+C to stop
> the manual test.

### 2. Create the Supervisor program

```bash
sudo nano /etc/supervisor/conf.d/ecral-reverb.conf
```

Contents:

```ini
[program:ecral-reverb]
process_name=%(program_name)s
command=php /var/www/ecral/artisan reverb:start
autostart=true
autorestart=true
user=root
redirect_stderr=true
stdout_logfile=/var/www/ecral/storage/logs/reverb.log
stopwaitsecs=3600
```

### 3. Load and start the program

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start ecral-reverb
```

Expected results:

```
ecral-reverb: available
ecral-reverb: added process group
```

(`ERROR (already started)` is harmless — `update` auto-starts it, so it was already running.)

### 4. Confirm it is running and listening

```bash
sudo supervisorctl status ecral-reverb
sudo ss -tlnp | grep 8080
```

Expected:

```
ecral-reverb   RUNNING   pid 172278, uptime 0:00:34
LISTEN 0  511  0.0.0.0:8080  0.0.0.0:*  users:(("php",pid=172278,...))
```

### 5. Confirm internal HTTP reaches Reverb

```bash
curl -v http://localhost:8080/app/ecral-key
```

Expected: `HTTP/1.1 500 Internal Server Error`.

> The `500` is **expected** — `curl` sends a plain HTTP request, not a real WebSocket
> handshake, so Reverb rejects it. The point is that it now **responds** instead of
> refusing the connection.

---

## Fix Part 2 — Nginx reverse proxy on port 8087 (with SSL)

The frontend connects to `wss://<domain>:8087`. Nginx must listen on 8087 with SSL and
forward internally to Reverb on `127.0.0.1:8080`.

### 1. Confirm the SSL certificate path (issued by Certbot)

```bash
sudo nginx -T | grep -i ssl_certificate
```

Result:

```
ssl_certificate /etc/letsencrypt/live/apis.ecral.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/apis.ecral.com/privkey.pem;
```

### 2. Back up the site config before editing

```bash
sudo cp /etc/nginx/sites-available/ecral /etc/nginx/sites-available/ecral.backup
```

### 3. Add the port-8087 server block

Edit the site config:

```bash
sudo nano /etc/nginx/sites-available/ecral
```

Append this **new server block** at the end of the file (after the existing 443 and 80
blocks):

```nginx
server {
    listen 8087 ssl;
    server_name apis.ecral.com;

    ssl_certificate /etc/letsencrypt/live/apis.ecral.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/apis.ecral.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Reverb's native Pusher-protocol endpoint
    location /app/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }

    # Bridge: rewrite socket.io-style requests to Reverb's /app/{key}
    location /socket.io/ {
        rewrite ^/socket.io/.*$ /app/ecral-key break;
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }
}
```

> **Why two `location` blocks?**
> - `/app/` is Reverb's real endpoint (Pusher protocol).
> - `/socket.io/` exists because the frontend connects with a socket.io client. The
>   `rewrite` maps that path onto Reverb's `/app/ecral-key`. This is a **temporary
>   bridge** — it lets the connection open, but socket.io (Engine.IO) and Reverb
>   (Pusher) are different protocols, so message framing may still differ. The clean
>   fix is on the frontend (use `laravel-echo` + `pusher-js` with `broadcaster: 'reverb'`).
> If your frontend already uses Reverb correctly, you can omit the `/socket.io/` block.

### 4. Test syntax and reload

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Expected:

```
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 5. Confirm Nginx is listening on 8087

```bash
sudo ss -tlnp | grep 8087
```

Expected: a `LISTEN ... 0.0.0.0:8087 ... nginx` line.

### 6. Confirm the full external path (SSL → Nginx → Reverb)

```bash
curl -vk https://localhost:8087/app/ecral-key
```

Expected: TLS handshake succeeds, then `HTTP/1.1 500 Internal Server Error` with
`Server: nginx/1.24.0`. This confirms the request reached Reverb through Nginx.

### 7. (Optional) Confirm a real WebSocket handshake

```bash
curl -vk --http1.1 \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: $(head -c16 /dev/urandom | base64)" \
  "https://localhost:8087/app/ecral-key"
```

Expected: `HTTP/1.1 101 Switching Protocols` = WebSocket works.

---

## Firewall

### Local firewall (ufw)

```bash
sudo ufw status
```

On this server it was `inactive`, so nothing was blocked locally. If it is active,
open the port:

```bash
sudo ufw allow 8087
```

### Cloud firewall

If the server is on a cloud provider (e.g. Hetzner/DigitalOcean/AWS), also open
**inbound TCP 8087** in the provider's firewall / security group. This is separate from
ufw and can block the port even when everything on the server is correct.

---

## Final verification (from a client machine)

Send a request (e.g. from Postman) to:

```
https://<domain>:8087/app/ecral-key
```

- `500 Internal Server Error` = success (path works end-to-end).
- `ECONNREFUSED` / timeout = the cloud firewall is still blocking port 8087.

Then open the frontend and check the browser console — the WebSocket should connect.

> Tip: if you see `ERR_BLOCKED_BY_CLIENT` in the console, that's a browser
> extension/ad-blocker, not the server. Test in an Incognito window.

---

## Final Nginx config (full file for reference)

```nginx
server {
    server_name apis.ecral.com;
    root /var/www/ecral/public;
    index index.php index.html;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    charset utf-8;
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt { access_log off; log_not_found off; }
    error_page 404 /index.php;
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
    }
    location ~ /\.(?!well-known).* {
        deny all;
    }
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/apis.ecral.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/apis.ecral.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}
server {
    if ($host = apis.ecral.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    listen 80;
    server_name apis.ecral.com;
    return 404; # managed by Certbot
}
server {
    listen 8087 ssl;
    server_name apis.ecral.com;
    ssl_certificate /etc/letsencrypt/live/apis.ecral.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/apis.ecral.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    location /app/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }
    location /socket.io/ {
        rewrite ^/socket.io/.*$ /app/ecral-key break;
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }
}
```

---

## Relevant .env (Reverb) values

```
REVERB_APP_ID=ecral-app
REVERB_APP_KEY=ecral-key
REVERB_APP_SECRET=ecral-secret
REVERB_HOST=localhost      # internal bind host for the Reverb process
REVERB_PORT=8080           # internal port (Nginx proxies to this)
REVERB_SCHEME=http         # internal scheme (SSL is terminated by Nginx on 8087)
```

> These are the **internal** values used by the Reverb server itself. External clients
> connect via `wss://<domain>:8087`, and Nginx handles the SSL and proxies to
> `127.0.0.1:8080`. The frontend broadcasting config should point to the public
> host/port (`<domain>` / `8087`, `wss`), not `localhost`.

---

## Values to change on a new server

| Item | This server | Change to |
|------|-------------|-----------|
| App path | `/var/www/ecral` | new project path |
| Domain | `apis.ecral.com` | new domain |
| SSL cert path | `/etc/letsencrypt/live/apis.ecral.com/` | new domain's Certbot path |
| PHP-FPM socket | `php8.3-fpm.sock` | installed PHP version |
| Supervisor program name | `ecral-reverb` | e.g. `<project>-reverb` |
| Site config file | `/etc/nginx/sites-available/ecral` | new site file |
| App key in rewrite | `ecral-key` | value of `REVERB_APP_KEY` |
| External port | `8087` | keep or change (must match frontend + firewall) |
| Internal Reverb port | `8080` | keep or change (must match `REVERB_PORT`) |

### Before starting on a new server, make sure:

1. Laravel Reverb is installed (`composer require laravel/reverb` + `php artisan reverb:install`).
2. A valid SSL certificate exists for the domain (e.g. `sudo certbot --nginx -d <domain>`).
3. Supervisor is installed (`sudo apt install supervisor`).
4. The chosen external port is open in the cloud firewall / security group.

---

## Quick command recap (new server, in order)

```bash
# 1. Supervisor program for Reverb
sudo nano /etc/supervisor/conf.d/<project>-reverb.conf   # paste the [program] block
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl status

# 2. Verify Reverb is listening
sudo ss -tlnp | grep 8080

# 3. Nginx 8087 server block
sudo cp /etc/nginx/sites-available/<site> /etc/nginx/sites-available/<site>.backup
sudo nano /etc/nginx/sites-available/<site>            # add the 8087 server block
sudo nginx -t
sudo systemctl reload nginx
sudo ss -tlnp | grep 8087

# 4. Firewall (cloud provider) — open inbound TCP 8087

# 5. Verify end-to-end
curl -vk https://localhost:8087/app/<REVERB_APP_KEY>
```
