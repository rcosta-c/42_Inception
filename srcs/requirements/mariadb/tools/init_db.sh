#!/bin/bash
set -e

# Date and Time for logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

SQL_USER=$(cat /run/secrets/mysql_user)
SQL_PASS=$(cat /run/secrets/mysql_password)
SQL_ROOT_PASS=$(cat /run/secrets/mysql_rootpassword)

log "Preparing MariaDB..."
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld
chown -R mysql:mysql /var/lib/mysql

# if first time mariadb initializes
if [ ! -d "/var/lib/mysql/mysql" ]; then
    log "First init detected. Installing database..."
    
    # initialize the database
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    # temporary file for SQL commands
    tempfile=$(mktemp)
    cat > "$tempfile" <<-EOF
USE mysql;
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASS}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${SQL_ROOT_PASS}' WITH GRANT OPTION;
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
    
    # starts mariadb to complete configuration
    log "Configurating database..."
    mysqld --user=mysql --bootstrap --verbose=0 --skip-networking=0 < "$tempfile"
    rm -f "$tempfile"
    
    log "Database config done!"
else
    log "Database is already there. Inicializing..."
fi

unset SQL_USER SQL_PASS SQL_ROOT_PASS

log "Starting MariaDB..."
exec mysqld --user=mysql --console