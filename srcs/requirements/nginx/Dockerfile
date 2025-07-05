FROM debian:buster

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl \
    && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=PT/ST=Portugal/L=Porto/O=42/OU=42/CN=localhost"

COPY conf/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/www/wordpress && \
    chown -R www-data:www-data /var/www/wordpress

#COPY tools/index.html /var/www/html/index.html

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]