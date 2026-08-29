RabbitMQ installing:
sudo apt update
sudo apt install -y rabbitmq-server
sudo systemctl status rabbitmq-server
sudo rabbitmq-plugins enable rabbitmq_management (to enable the UI) accessed via http://SERVER_IP:15672
Create Production User
sudo rabbitmqctl add_user prod_user strong_password
sudo rabbitmqctl set_user_tags prod_user administrator
sudo rabbitmqctl set_permissions -p / prod_user ".*" ".*" ".*"
Firewall Rules
sudo ufw allow 5672
sudo ufw allow 15672
Change .env
QUEUE_CONNECTION=rabbitmq
RABBITMQ_HOST=127.0.0.1
RABBITMQ_PORT=5672
RABBITMQ_USER=prod_user
RABBITMQ_PASSWORD=strong_password
RABBITMQ_VHOST=/
Make sure laravel package is installed (optional)
composer show | grep rabbitmq
php artisan optimize:clear
php artisan config:cache
Supervisor (REQUIRED FOR PROD)
sudo apt install -y supervisor
sudo nano /etc/supervisor/conf.d/laravel-rabbitmq.conf
[program:laravel-rabbitmq]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/project/artisan queue:work rabbitmq --sleep=3 --tries=3
autostart=true
autorestart=true
numprocs=1
user=www-data
redirect_stderr=true
stdout_logfile=/var/www/project/storage/logs/worker.log
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start laravel-rabbitmq:*
	•		⁃	sudo supervisorctl status