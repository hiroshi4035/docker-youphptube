FROM alpine

ARG HTTP_PORT="10080"
ARG HTTPS_PORT="10443"

ENV DOMAIN your.domain
ENV DOMAIN_PROTOCOL http
ENV SITE_TITLE your_site_title
ENV ADMIN_PASSWORD password
ENV ADMIN_EMAIL webmaster@your.domain
ENV DB_HOST localhost
ENV DB_USER root
ENV DB_PASSWORD password
ENV LANG en

ADD configuration.php /home/
ADD docker-entrypoint.sh /usr/local/bin/
ADD gencerts.sh /usr/local/bin/
WORKDIR /var/www/localhost/htdocs
RUN apk update  \
    && apk add --no-cache git curl certbot acme-client openssl mysql-client apache2 apache2-ssl php7 php7-apache2 php7-mysqlnd php7-mysqli php7-json php7-session php7-curl php7-gd php7-intl php7-exif php7-mbstring ffmpeg exiftool perl-image-exiftool python \
    && rm -rf /var/cache/apk/* \
    && mkdir /run/apache2 \
    && sed -ri \
           -e 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g' \
           -e 's!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g' \
           -e 's!^#(LoadModule rewrite_module .*)$!\1!g' \
           -e 's!^(\s*AllowOverride) None.*$!\1 All!g' \
           -e 's!^(\s*Listen) 80.*$!\1 '${HTTP_PORT}'!g' \
           "/etc/apache2/httpd.conf" \
       \
    && sed -ri \
           -e 's!^(max_execution_time = )(.*)$!\1 72000!g' \
           -e 's!^(post_max_size = )(.*)$!\1 10G!g' \
           -e 's!^(upload_max_filesize = )(.*)$!\1 10G!g' \
           -e 's!^(memory_limit = )(.*)$!\1 10G!g' \
           "/etc/php7/php.ini" \
       \
    && sed -ri \
           -e 's!^(\s*Listen) 443.*$!\1 '${HTTPS_PORT}'!g' \
           -e 's!^(\s*<VirtualHost)(\s+\S+):443!\1\2:'${HTTPS_PORT}'!g' \
           -e 's!^(\s*ServerName)(\s+\S+):443!\1\2:'${HTTPS_PORT}'!g' \
           "/etc/apache2/conf.d/ssl.conf" \
       \
    && rm -f index.html \
    && git clone https://github.com/DanielnetoDotCom/YouPHPTube.git \
    && mv YouPHPTube/* . \
    && mv YouPHPTube/.[!.]* . \
    && rm -rf YouPHPTube \
    && chmod a+rx /usr/local/bin/docker-entrypoint.sh \
    && chmod a+rx /usr/local/bin/gencerts.sh \
    && mkdir videos \
    && chmod 777 videos \
    && git clone https://github.com/DanielnetoDotCom/YouPHPTube-Encoder.git \
    && mv YouPHPTube-Encoder encoder \
    && mkdir encoder/videos \
    && chmod 777 encoder/videos \
    && chown -R apache:apache /var/www

VOLUME ["/var/www/localhost/htdocs/videos", "/var/www/localhost/htdocs/encoder/videos"]
EXPOSE ${HTTP_PORT} ${HTTPS_PORT}
CMD ["docker-entrypoint.sh"]
