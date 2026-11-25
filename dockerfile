FROM php:8.4-apache

# Dépendances système + extensions PHP pour Symfony et MySQL
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        unzip \
        curl \
        libicu-dev \
        libzip-dev \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        intl \
        zip \
        opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Apache : le site pointe sur public/ (seul dossier exposé au web)
RUN a2enmod rewrite \
    && printf '<VirtualHost *:80>\n\
    DocumentRoot /var/www/html/public\n\
    <Directory /var/www/html/public>\n\
        AllowOverride All\n\
        Require all granted\n\
        FallbackResource /index.php\n\
    </Directory>\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>\n' > /etc/apache2/sites-available/000-default.conf

# www-data prend l'id de mon utilisateur WSL (1000)
# → Apache peut écrire dans var/ et mes fichiers restent modifiables, sans chmod 777
RUN groupmod -g 1000 www-data && usermod -u 1000 -g 1000 www-data

WORKDIR /var/www/html

EXPOSE 80