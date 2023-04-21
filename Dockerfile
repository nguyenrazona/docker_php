FROM php:5.6-apache

# Change Timezone
ENV TZ=Asia/Tokyo
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo ${TZ} > /etc/timezone

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install packages
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    openssl libssl-dev \
    libxml2-dev

# Common PHP Extensions
RUN docker-php-ext-install -j$(nproc) iconv mcrypt pdo_mysql mbstring xml tokenizer zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install mysql

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
COPY php5.6.ini ${PHP_INI_DIR}/php.ini

WORKDIR ${APACHE_DOCUMENT_ROOT}

CMD ["apache2-foreground"]

EXPOSE 80
EXPOSE 443
