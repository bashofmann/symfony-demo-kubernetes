# Install frontend dependencies and build JS and CSS
FROM kkarczmarczyk/node-yarn:latest AS yarn

WORKDIR /var/www/html

COPY package.json /var/www/html/
COPY yarn.lock /var/www/html/

RUN yarn install

COPY webpack.config.js /var/www/html/
COPY assets /var/www/html/assets/

RUN mkdir -p /var/www/html/public/build && yarn run build

# Install PHP dependencies
FROM composer AS composer

WORKDIR /var/www/html

COPY composer.* /var/www/html/
RUN composer install

# Build actual image
FROM php:7.2-apache

WORKDIR /var/www/html

# install packages
RUN apt-get update -y && \
  apt-get install -y --no-install-recommends \
  curl git openssl \
  less vim wget unzip rsync git mysql-client \
  libcurl4-openssl-dev libfreetype6 libjpeg62-turbo libpng-dev libjpeg-dev libxml2-dev libxpm4 \
  libicu-dev coreutils openssh-client libsqlite3-dev && \
  apt-get clean && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

# install php extensions
RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/local/ && \
  docker-php-ext-install -j$(nproc) iconv intl pdo_sqlite curl json xml mbstring zip bcmath soap pdo_mysql gd

# apache config
RUN /usr/sbin/a2enmod rewrite && /usr/sbin/a2enmod headers && /usr/sbin/a2enmod expires
COPY ./container/apache.conf /etc/apache2/sites-available/000-default.conf

# copy needed files from build containers
COPY --from=yarn /var/www/html/public/build/ /var/www/html/public/build/
COPY --from=composer /var/www/html/vendor/ /var/www/html/vendor/

COPY . /var/www/html/

# Ensure that cache, log and session directories are writable
RUN mkdir -p /var/www/html/var && chown -R www-data:www-data /var/www/html/var
