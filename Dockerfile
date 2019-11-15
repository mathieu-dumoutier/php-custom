# Dockerfile for Gitlab CI
FROM php:7.3-fpm-alpine
ARG TIMEZONE

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
# Set timezone
RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && echo ${TIMEZONE} > /etc/timezone \
&& printf '[PHP]\ndate.timezone = "%s"\n', ${TIMEZONE} > /usr/local/etc/php/conf.d/tzone.ini

# Install GD
RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev && \
  docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  docker-php-ext-install -j${NPROC} gd && \
  apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev

# Requirements for Laravel/Symfony
RUN apk add --update $PHPIZE_DEPS icu icu-dev openldap-dev libldap zlib-dev libzip-dev libxml2-dev nodejs nodejs-npm git \
&& docker-php-ext-install pdo_mysql zip intl opcache pdo pdo_mysql soap \
&& pecl install apcu \
&& echo "extension=apcu.so" > /usr/local/etc/php/conf.d/apcu.ini \
&& pecl install pecl/apcu_bc-1.0.3 \
&& echo "extension=apc.so" >> /usr/local/etc/php/conf.d/apcu.ini

# Special config PHP
RUN echo "memory_limit=256M" >> /usr/local/etc/php/conf.d/special.ini \
&& echo "error_log=/var/log/php-fpm.log" >> /usr/local/etc/php/conf.d/special.ini \
&& echo "log_errors=1" >> /usr/local/etc/php/conf.d/special.ini \
&& echo "realpath_cache_size=4096K" >> /usr/local/etc/php/conf.d/special.ini \
&& echo "realpath_cache_ttl=600" >> /usr/local/etc/php/conf.d/special.ini \
&& echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/special.ini \
&& echo "opcache.max_accelerated_files=20000" >> /usr/local/etc/php/conf.d/special.ini

# Install xdebug
RUN pecl install xdebug \
&& docker-php-ext-enable xdebug \
&& echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
&& echo "display_startup_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
&& echo "display_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
&& echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
&& echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
&& echo "xdebug.idekey=\"PHPSTORM\"" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
&& echo "xdebug.remote_port=9001" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Install yarn
RUN curl -o- -L https://yarnpkg.com/install.sh | /bin/sh \
&& ln -s /root/.yarn/bin/yarn /usr/local/bin/yarn

WORKDIR /var/www/html
