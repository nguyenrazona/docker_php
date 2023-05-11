FROM php:5.6-apache

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
    libpq-dev \
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
    pdo_mysql \
    pdo_pgsql \
    pgsql

# Install Mysql client commands
RUN apt-get install -y default-mysql-client

# Apache configuration
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN echo "\nServerName localhost\n" >> /etc/apache2/apache2.conf
RUN a2enmod rewrite headers

# Enable SSI
RUN sed -ri -e "s!	Options Indexes FollowSymLinks!	Options Indexes FollowSymLinks Includes\n	AddType text/html .html .shtml\n	AddOutputFilter INCLUDES .html .shtml!g" /etc/apache2/apache2.conf
RUN a2enmod include

# Make a test file
RUN mkdir ${APACHE_DOCUMENT_ROOT} && echo 'TEST OK' >> ${APACHE_DOCUMENT_ROOT}/index.html

# Config HTTPS
# RUN apt-get install -y dialog apt-utils
# RUN apt install -y ssl-cert
# RUN make-ssl-cert generate-default-snakeoil
# RUN a2enmod ssl
# RUN a2ensite default-ssl
# RUN service apache2 restart

# Copy PHP config
COPY php5.6.ini ${PHP_INI_DIR}/php.ini

WORKDIR ${APACHE_DOCUMENT_ROOT}

EXPOSE 80
