#!/bin/bash
set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

SQL_USER=$(cat /run/secrets/mysql_user)
SQL_PASS=$(cat /run/secrets/mysql_password)
WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user)
WP_ADMIN_PASS=$(cat /run/secrets/wp_adminpassword)
WP_ADMIN_EMAIL=$(cat /run/secrets/wp_admin_mail)
WP_URL="https://${DOMAIN_NAME}"

# Waiting for DB (MariaDB)
log "Checking database connection..."
max_retries=30
counter=0
while ! mysqladmin ping -h mariadb -u $SQL_USER -p$SQL_PASS --silent; do
    counter=$((counter+1))
    if [ $counter -gt $max_retries ]; then
        log "ERROR: Unable to connect to database after $max_retries attempts."
        exit 1
    fi
    log "MariaDB is not yet available. Waiting 5 seconds... (Retry $counter/$max_retries)"
    sleep 5
done
log "Connection to database established!"

# Check that the database exists and has the correct permissions
log "Checking database..."
if ! mysql -h mariadb -u $SQL_USER -p$SQL_PASS -e "USE $MYSQL_DATABASE;" 2>/dev/null; then
    log "ERROR: Database $MYSQL_DATABASE without access!"
    exit 1
fi
log "Database $MYSQL_DATABASE with access!"

WP_DIR="/var/www/wordpress"
cd $WP_DIR

# Installing WordPress if needed
if [ ! -f "wp-config.php" ]; then
    log "WordPress not found. Starting instalation..."

    wp core download --allow-root

    log "Crating wp-config.php..."
    wp config create \
        --dbname=$MYSQL_DATABASE \
        --dbuser=$SQL_USER \
        --dbpass=$SQL_PASS \
        --dbhost=mariadb \
        --allow-root

    # Add extra settings to wp-config.php
    wp config set WP_DEBUG false --raw --allow-root
    wp config set WP_DEBUG_DISPLAY false --raw --allow-root
    wp config set WP_DEBUG_LOG false --raw --allow-root

    # validating email before instalation
    if [[ ! "$WP_ADMIN_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log "WARNING: Invalid email detected: $WP_ADMIN_EMAIL"
        log "You should use something like: admin@example.com"
        WP_ADMIN_EMAIL="admin@example.com"
    fi

    log "Installing WordPress..."
    wp core install \
        --url=$WP_URL \
        --title="$WP_TITLE" \
        --admin_user=$WP_ADMIN_USER \
        --admin_password=$WP_ADMIN_PASS \
        --admin_email=$WP_ADMIN_EMAIL \
        --skip-email \
        --allow-root

    log "Creates extra user..."
    wp user create \
        $WP_USER $WP_USER_EMAIL \
        --role=author \
        --user_pass=$WP_USER_PASSWORD \
        --allow-root

    # Config basic options
    wp option update blogdescription "42 School Inception Project" --allow-root
    wp option update permalink_structure "/%postname%/" --allow-root

    # Theme
    wp theme install twentytwentyone --activate --allow-root

    # Post
    wp post create \
        --post_type=post \
        --post_title="Welcome to ao Inception!" \
        --post_content="This is the Inception Project from 42. WordPress working with Docker!" \
        --post_status=publish \
        --post_author=1 \
        --allow-root

    log "WordPress instalation completed!"
else
    log "WordPress already instaled."
fi

log "Configurating PHP-FPM..."
sed -i 's/listen = .*/listen = 9000/' /etc/php/7.3/fpm/pool.d/www.conf
sed -i 's/;listen.owner = .*/listen.owner = www-data/' /etc/php/7.3/fpm/pool.d/www.conf
sed -i 's/;listen.group = .*/listen.group = www-data/' /etc/php/7.3/fpm/pool.d/www.conf
sed -i 's/;listen.mode = .*/listen.mode = 0660/' /etc/php/7.3/fpm/pool.d/www.conf

# Permissions
log "correcting permissions..."
chown -R www-data:www-data $WP_DIR
chmod -R 755 $WP_DIR
find $WP_DIR -type d -exec chmod 755 {} \;
find $WP_DIR -type f -exec chmod 644 {} \;

mkdir -p /var/lib/php/sessions /run/php
chown -R www-data:www-data /var/lib/php/sessions
chown -R www-data:www-data /run/php

log "Checking PHP-FPM config..."
if ! php-fpm7.3 -t; then
    log "ERROR: Invalid config in PHP-FPM!"
    exit 1
fi

unset SQL_USER SQL_PASS WP_ADMIN_USER WP_ADMIN_PASS WP_ADMIN_EMAIL WP_USER WP_USER_PASSWORD WP_USER_EMAIL

log "Starting PHP-FPM..."
exec php-fpm7.3 -F