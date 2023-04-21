FROM php:8.0-apache

# Change Timezone
ENV TZ=Asia/Tokyo
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo ${TZ} > /etc/timezone

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install packages
RUN apt-get update && apt-get install -y \
    zip \
    curl \
    sudo \
    unzip \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    g++

# Common PHP Extensions
RUN docker-php-ext-install \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar \
    pdo_mysql

# Install Redis client commands
RUN pecl install -o -f redis && docker-php-ext-enable redis

# Install Mysql client commands
RUN apt-get install -y default-mysql-client

# Apache configuration
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN echo "\nServerName localhost\n" >> /etc/apache2/apache2.conf
RUN a2enmod rewrite headers

# Make a test file
RUN mkdir ${APACHE_DOCUMENT_ROOT} && echo 'TEST OK' >> ${APACHE_DOCUMENT_ROOT}/index.html

# Config HTTPS
RUN apt install -y ssl-cert
RUN make-ssl-cert generate-default-snakeoil
RUN a2enmod ssl
RUN a2ensite default-ssl
RUN service apache2 restart

# Copy PHP config
COPY php8.0.ini ${PHP_INI_DIR}/php.ini

WORKDIR ${APACHE_DOCUMENT_ROOT}

CMD ["apache2-foreground"]

EXPOSE 80
EXPOSE 443
