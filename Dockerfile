FROM php:fpm

LABEL Maintainer="Ansley Leung" \
      Description="latest PHP7 fpm Docker image. Use `docker-php-ext-install extension_name` to install Extensions." \
      License="MIT License" \
      Version="1.0"

ARG DEBIAN_FRONTEND=noninteractive

# if you want use APT mirror then uncomment, modify the mirror address to which you favor
# RUN sed -i 's|deb.debian.org|mirrors.ustc.edu.cn|g' /etc/apt/sources.list \
#    && sed -i 's|security.debian.org|mirrors.ustc.edu.cn/debian-security/|g' /etc/apt/sources.list

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get -y install dialog apt-utils apt-transport-https --no-install-recommends

# if you want use HTTPS mirror then uncomment, modify the mirror address to which you favor
# RUN sed -i 's|http://mirrors.ustc.edu.cn|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list

# Extensions: If missing, install them directly by `docker-php-ext-install extension_name`

# Notice:
# 1. Mcrypt was DEPRECATED in PHP 7.1.0, and REMOVED in PHP 7.2.0.
# 2. opcache requires PHP version >= 7.0.0.
# 3. soap requires libxml2-dev.
# 4. xml, xmlrpc, wddx require libxml2-dev and libxslt-dev.
# 5. Line `&& :\` is just for better reading and do nothing.
RUN apt-get update \
    && apt-get upgrade -y \
    && :\
    && apt-get install -y curl libfreetype6-dev libjpeg62-turbo-dev libpng-dev --no-install-recommends \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && :\
    && apt-get install -y libicu-dev --no-install-recommends \
    && docker-php-ext-install intl \
    && :\
    && apt-get install -y libxml2-dev libxslt-dev --no-install-recommends \
    && docker-php-ext-install soap \
    && docker-php-ext-install xsl \
    && docker-php-ext-install xmlrpc \
    && docker-php-ext-install wddx \
    && :\
    && apt-get install -y libbz2-dev --no-install-recommends \
    && docker-php-ext-install bz2 \
    && :\
    && docker-php-ext-install zip \
    && docker-php-ext-install pcntl \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install exif \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install calendar \
    && docker-php-ext-install sockets \
    && docker-php-ext-install gettext \
    && docker-php-ext-install shmop \
    && docker-php-ext-install sysvmsg \
    && docker-php-ext-install sysvsem \
    && docker-php-ext-install sysvshm \
    && docker-php-ext-install opcache \
    && :\
    && apt-get install -y libpq-dev --no-install-recommends \
    && docker-php-ext-install pdo_pgsql \
    && :\
    && apt-get install -y curl libcurl3 libcurl4-openssl-dev --no-install-recommends \
    && docker-php-ext-install curl \
    && :\
    && apt-get install -y libpspell-dev aspell-en --no-install-recommends \
    && docker-php-ext-install pspell \
    && :\
    && apt-get install -y libssl-dev libc-client-dev libkrb5-dev --no-install-recommends \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap
    #&& docker-php-ext-install pdo_firebird \
    #&& docker-php-ext-install pdo_dblib \
    #&& docker-php-ext-install pdo_oci \
    #&& docker-php-ext-install pdo_odbc \
    #&& docker-php-ext-install pgsql \
    #&& docker-php-ext-install oci8 \
    #&& docker-php-ext-install odbc \
    #&& docker-php-ext-install dba \
    #&& docker-php-ext-install interbase \
    #&& :\
    #&& apt-get install -y libmcrypt-dev --no-install-recommends \
    #&& docker-php-ext-install mcrypt \
    #&& :\
    #&& apt-get install -y libreadline-dev --no-install-recommends \
    #&& docker-php-ext-install readline \
    #&& :\
    #&& apt-get install -y libsnmp-dev snmp --no-install-recommends \
    #&& docker-php-ext-install snmp \
    #&& :\
    #&& apt-get install -y librecode0 librecode-dev --no-install-recommends \
    #&& docker-php-ext-install recode \
    #&& :\
    #&& apt-get install -y libtidy-dev --no-install-recommends \
    #&& docker-php-ext-install tidy \
    #&& :\
    #&& apt-get install -y libgmp-dev --no-install-recommends \
    #&& ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
    #&& docker-php-ext-install gmp \
    #&& :\
    #&& apt-get install -y postgresql-client mysql-client --no-install-recommends \
    #&& :\
    #&& apt-get install -y libldb-dev libldap2-dev --no-install-recommends \
    #&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    #&& docker-php-ext-install ldap \

# Composer
# RUN curl -sS https://install.phpcomposer.com/installer | php -- --install-dir=/usr/bin/ --filename=composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Install extension using pecl
# Notice: if pecl install get error
#    No releases available for package "pecl.php.net/xxx"
# or
#    Package "xxx" does not have REST xml available
# Please turn on proxy (The proxy IP may be docker host IP or others):
# RUN pear config-set http_proxy http://192.168.0.100:8118

RUN apt-get install -y libpcre3 libpcre3-dev  --no-install-recommends \
    && pecl install oauth \
    && docker-php-ext-enable oauth \
    && :\
    && pecl install redis \
    && docker-php-ext-enable redis \
    && :\
    && pecl install mongodb \
    && docker-php-ext-enable mongodb \
    && :\
    && apt-get install -y libmagickwand-dev --no-install-recommends \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && :\
    && apt-get install -y libmemcached-dev zlib1g-dev --no-install-recommends \
    && pecl install memcached \
    && docker-php-ext-enable memcached

RUN pecl install xdebug-2.6.0alpha1 \
    && docker-php-ext-enable xdebug

# some clean job
RUN apt-get clean \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*
