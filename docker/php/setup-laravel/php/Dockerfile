FROM php:7.2-fpm

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    libonig-dev \
    libxml2-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libfreetype6-dev \
    libwebp-dev \
    libzip-dev \
    && docker-php-ext-configure gd \
        --with-freetype-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd exif pdo_mysql zip \
    && pecl install apcu redis-4.3.0 \
    && echo "extension=apcu.so" > /usr/local/etc/php/conf.d/apcu.ini \
    && echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www/html

COPY ./emr-php/composer.json /var/www/html/

RUN composer install --optimize-autoloader --no-interaction --no-scripts

COPY ./emr-php /var/www/html


RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Ensure PHP-FPM runs as www-data and not root
USER www-data
# Expose the port that PHP-FPM will listen on
EXPOSE 9000
