FROM php:7.2.9-fpm

LABEL Maintainer="Ansley Leung" \
      Description="Latest PHP7 fpm Docker image. Use `docker-php-ext-install extension_name` to install Extensions." \
      License="MIT License" \
      Version="7.2.9"

ARG DEBIAN_FRONTEND=noninteractive

# Uncomment if you want use APT mirror, modify the mirror address to which you favor
# RUN sed -i 's|deb.debian.org|mirrors.ustc.edu.cn|g' /etc/apt/sources.list \
#     && sed -i 's|security.debian.org|mirrors.ustc.edu.cn/debian-security/|g' /etc/apt/sources.list

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y apt-utils apt-transport-https dialog --no-install-recommends

# Uncommentif you want use HTTPS mirror, modify the mirror address to which you favor
# RUN sed -i 's|http://mirrors.ustc.edu.cn|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list

RUN apt-get update && \
    apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev libicu-dev \
            libxml2-dev libxslt-dev libbz2-dev libpspell-dev aspell-en \
            curl libcurl3 libcurl4-openssl-dev libssl-dev libc-client-dev libkrb5-dev \
            libpcre3 libpcre3-dev libmagickwand-dev libmemcached-dev zlib1g-dev \
            libpq-dev nghttp2 libnghttp2-dev --no-install-recommends && \
    apt-get clean && apt-get autoclean && apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

    # libmcrypt-dev libsnmp-dev snmp librecode0 librecode-dev && \
    # libtidy-dev libgmp-dev libldb-dev libldap2-dev postgresql-client mysql-client

# Extensions: install directly by `docker-php-ext-install extension_name`
# Notice:
# 1. Mcrypt was DEPRECATED in PHP 7.1.0, and REMOVED in PHP 7.2.0.
# 2. opcache requires PHP version >= 7.0.0.
# 3. Line `&& :\` is just for better reading and do nothing.
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install gd && \
    : && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install imap && \
    : && \
    docker-php-ext-configure opcache --enable-opcache && \
    docker-php-ext-install opcache && \
    : && \
    docker-php-ext-install bcmath calendar exif gettext intl pspell pcntl bz2 zip && \
    docker-php-ext-install shmop soap sockets sysvmsg sysvsem sysvshm wddx xsl xmlrpc && \
    docker-php-ext-install mysqli pdo_mysql pdo_pgsql

    # docker-php-ext-install pdo_firebird pdo_dblib pdo_oci pdo_odbc pgsql oci8 odbc dba interbase && \
    # : && \
    # docker-php-ext-install mcrypt snmp recode tidy
    # : && \
    # ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h && \
    # docker-php-ext-install gmp && \
    # : && \
    # docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu && \
    # docker-php-ext-install ldap

# set recommended opcache settings
# https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
		echo 'opcache.file_cache=/tmp'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# remove PHP version from the X-Powered-By HTTP header
# test: curl -I -H "Accept-Encoding: gzip, deflate" https://www.yourdomain.com
RUN echo 'expose_php = off' > /usr/local/etc/php/conf.d/hide-header-version.ini

# Composer
# Prestissimo - composer parallel install plugin
# https://github.com/hirak/prestissimo
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /usr/local/share/composer

RUN mkdir -p /usr/local/share/composer && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer && \
    composer g require "hirak/prestissimo:^0.3.7"
# wget https://dl.laravel-china.org/composer.phar -O /usr/local/bin/composer && chmod a+x /usr/local/bin/composer

# Install extension using pecl
# Notice: if pecl install get error
#    No releases available for package "pecl.php.net/xxx"
# or
#    Package "xxx" does not have REST xml available
# Please turn on proxy (The proxy IP may be docker host IP or others):
# RUN pear config-set http_proxy http://192.168.0.100:8118

RUN pecl install imagick memcached mongodb redis oauth xdebug && \
    docker-php-ext-enable imagick memcached mongodb redis oauth xdebug

# swoole
# https://github.com/swoole/swoole-src
# hiredis( for swoole )
# https://github.com/redis/hiredis
RUN cd /tmp && \
    curl -o ./hiredis.tar.gz https://github.com/redis/hiredis/archive/master.tar.gz -L && \
    tar zxvf ./hiredis.tar.gz && \
    mv hiredis* hiredis && \
    cd hiredis && \
    make -j && make install && ldconfig && \
    cd /tmp && \
    curl -o ./swoole.tar.gz https://github.com/swoole/swoole-src/archive/master.tar.gz -L && \
    tar zxvf ./swoole.tar.gz && \
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
    docker-php-ext-enable swoole && \
    rm -rf /tmp/*

# some clean job
# RUN apt-get clean && apt-get autoclean && apt-get autoremove && \
#     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
