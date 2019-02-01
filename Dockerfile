FROM php:7.1-cli
ENV NO_PROXY "10.56.2.250, 10.42.5.102, 127.0.0.1"

MAINTAINER Tobias Munk tobias@diemeisterei.de

# Install required system packages
RUN apt-get update && \
    apt-get -y install \
            git \
            zlib1g-dev \
            libssl-dev \
        --no-install-recommends && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install php extensions
RUN docker-php-ext-install \
    bcmath \
    zip

# Install pecl extensions
RUN pecl install \
        mongodb \
        xdebug-2.6.0beta1 && \
    docker-php-ext-enable \
        mongodb.so \
        xdebug

RUN pecl install -o -f redis \
&&  rm -rf /tmp/pear \
&&  docker-php-ext-enable redis

# Install php extensions
RUN docker-php-ext-install pdo pdo_mysql sockets


# Configure php
RUN echo "date.timezone = UTC" >> /usr/local/etc/php/php.ini

# Install composer
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN curl -sS https://getcomposer.org/installer | php -- \
        --filename=composer \
        --install-dir=/usr/local/bin
RUN composer global require --optimize-autoloader \
        "hirak/prestissimo"
# Prepare application
WORKDIR /repo

# Install vendor
COPY ./composer.json /repo/composer.json
RUN composer install --prefer-dist --optimize-autoloader

# Add source-code
COPY . /repo

ENV PATH /repo:${PATH}
ENTRYPOINT ["codecept"]

# Prepare host-volume working directory
RUN mkdir /project
WORKDIR /project

RUN useradd sybase \
    && usermod -u 1001 sybase \
    && groupmod -g 1001 sybase
USER sybase
