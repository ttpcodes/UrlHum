FROM node:13.8.0-alpine3.11 as frontend

COPY . /srv
WORKDIR /srv
RUN npm install
RUN npm run production

FROM php:7.3.14-alpine

RUN apk add --no-cache --virtual build-deps composer libpng-dev zlib-dev
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install gd
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install pdo
RUN docker-php-ext-install pdo_mysql

COPY --from=frontend /srv /srv
WORKDIR /srv
RUN composer install --optimize-autoloader

RUN apk del build-deps
RUN apk add --no-cache libpng libpq

RUN echo -e '#!/bin/sh\nuntil nc -z mysql 3306; do sleep 1; done\nphp artisan migrate -n --force\nif [ ! -f "/seed-done" ]; then php artisan db:seed -n --force && php artisan settings:set && touch /seed-done; fi\nphp artisan serve --host=0.0.0.0 --port=8000' > entrypoint.sh && chmod +x entrypoint.sh
CMD [ "./entrypoint.sh" ]
