# Use PHP 8.0 image as basis
FROM php:8.0-apache

# Update package inventory and install necessary packages
RUN apt-get update && apt-get install -y \
 libpq-dev\
 libmysqlclient-dev\
 zlib1g-dev\
 libicu-dev\
 g++\
 && docker-php-ext-install\
 pdo\
 pdo_mysql\
 intl\
 && a2enmod rewrite

# Copy the application files to the Docker container
COPY . /var/www/html/

# Change the folder owner to apache
RUN chown -R www-data:www-data /var/www/html

# Change working directory to application folder
WORKDIR /var/www/html

# Run Apache
CMD ["apache2-foreground"]