FROM php:7.2.9-fpm

LABEL Maintainer="Ansley Leung" \
      Description="Latest PHP7 fpm Docker image. Use `docker-php-ext-install extension_name` to install Extensions." \
      License="MIT License" \
      Version="7.2.9"

ARG DEBIAN_FRONTEND=noninteractive

# Uncomment if you want use APT mirror, modify the mirror address to which you favor
# RUN sed -i 's|deb.debian.org|mirrors.ustc.edu.cn|g' /etc/apt/sources.list \
#     && sed -i 's|security.debian.org|mirrors.ustc.edu.cn/debian-security/|g' /etc/apt/sources.list

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get -y install dialog apt-utils apt-transport-https --no-install-recommends

# Uncommentif you want use HTTPS mirror, modify the mirror address to which you favor
# RUN sed -i 's|http://mirrors.ustc.edu.cn|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev libicu-dev \
                          libxml2-dev libxslt-dev libbz2-dev libpq-dev libpspell-dev aspell-en \
                          curl libcurl3 libcurl4-openssl-dev libssl-dev libc-client-dev libkrb5-dev \
                          libpcre3 libpcre3-dev libmagickwand-dev libmemcached-dev zlib1g-dev --no-install-recommends

    #                      libmcrypt-dev libreadline-dev libedit-dev libsnmp-dev snmp librecode0 librecode-dev \
    #                      libtidy-dev libgmp-dev libldb-dev libldap2-dev postgresql-client mysql-client

# Extensions: install directly by `docker-php-ext-install extension_name`
# Notice:
# 1. Mcrypt was DEPRECATED in PHP 7.1.0, and REMOVED in PHP 7.2.0.
# 2. opcache requires PHP version >= 7.0.0.
# 5. Line `&& :\` is just for better reading and do nothing.
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && :\
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    && :\
    && docker-php-ext-install intl soap xsl xmlrpc wddx bz2 zip pcntl mbstring exif bcmath calendar \
    && docker-php-ext-install curl gettext shmop sockets sysvmsg sysvsem sysvshm opcache pspell \
    && docker-php-ext-install pdo_mysql mysqli pdo_pgsql

    #&& docker-php-ext-install pdo_firebird pdo_dblib pdo_oci pdo_odbc pgsql oci8 odbc dba interbase \
    #&& :\
    #&& docker-php-ext-install mcrypt readline snmp recode tidy
    #&& :\
    #&& ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
    #&& docker-php-ext-install gmp \
    #&& :\
    #&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    #&& docker-php-ext-install ldap

# set recommended opcache settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
		echo 'opcache.file_cache=/tmp'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Composer
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /usr/local/share/composer

RUN mkdir -p /usr/local/share/composer
# RUN curl -sS https://install.phpcomposer.com/installer | php -- --install-dir=/usr/bin/ --filename=composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Install Prestissimo - composer parallel install plugin
# https://github.com/hirak/prestissimo
RUN composer global require "hirak/prestissimo:^0.3.7"

# Install extension using pecl
# Notice: if pecl install get error
#    No releases available for package "pecl.php.net/xxx"
# or
#    Package "xxx" does not have REST xml available
# Please turn on proxy (The proxy IP may be docker host IP or others):
# RUN pear config-set http_proxy http://192.168.0.100:8118

RUN pecl install oauth imagick memcached redis mongodb xdebug \
    && docker-php-ext-enable oauth imagick memcached redis mongodb xdebug

# nghttp2( for swoole )
# https://github.com/nghttp2/nghttp2
RUN apt install -y nghttp2 libnghttp2-dev --no-install-recommends

# hiredis( for swoole )
# https://github.com/redis/hiredis
RUN mkdir -p ~/build && \
    cd ~/build && mkdir -p ./tmp && \
    rm -rf ./hiredis && \
    curl -o ./tmp/hiredis.tar.gz https://github.com/redis/hiredis/archive/master.tar.gz -L && \
    tar zxvf ./tmp/hiredis.tar.gz && \
    mv hiredis* hiredis && \
    cd hiredis && \
    make -j && make install && ldconfig

# swoole
# https://github.com/swoole/swoole-src
RUN mkdir -p ~/build && \
    cd ~/build && mkdir -p ./tmp && \
    rm -rf ./swoole-src && \
    curl -o ./tmp/swoole.tar.gz https://github.com/swoole/swoole-src/archive/master.tar.gz -L && \
    tar zxvf ./tmp/swoole.tar.gz && \
    mv swoole-src* swoole-src && \
    cd swoole-src && \
    phpize && \
    ./configure \
    --enable-coroutine \
    --enable-openssl  \
    --enable-http2  \
    --enable-async-redis \
    --enable-sockets \
    --enable-mysqlnd \
    --enable-coroutine-postgresql && \
    make clean && make && make install && \
    docker-php-ext-enable swoole

# some clean job
RUN apt-get clean \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*\
    && rm -rf ~/build
