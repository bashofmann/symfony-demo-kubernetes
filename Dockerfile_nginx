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
FROM alpine

WORKDIR /var/www/html

# copy needed files from build containers
COPY --from=yarn /var/www/html/public/build/ /var/www/html/public/build/
COPY --from=composer /var/www/html/vendor/ /var/www/html/vendor/

COPY . /var/www/html/
