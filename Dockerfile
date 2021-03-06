FROM centos:centos7

MAINTAINER maozihao

ENV SRC_DIR /usr/local
ENV PHP_VERSION 7.2.18
ENV SWOOLE_VERSION 4.3.3
ENV PHP_DIR /usr/local/php/${PHP_VERSION}
ENV PHP_INI_DIR /etc/php/${PHP_VERSION}/cli
ENV INIT_FILE ${PHP_INI_DIR}/conf.d
ENV HIREDIS_VERSION 0.13.3
ENV PHPREDIS_VERSION 3.1.6
ENV PHPDS_VERSION 1.2.4
ENV PHPINOTIFY_VERSION 2.0.0

#set ldconf
RUN echo "include /etc/ld.so.conf.d/*.conf" > /etc/ld.so.conf \
    && cd /etc/ld.so.conf.d \
    && echo "/usr/local/lib" > /etc/ld.so.conf.d/libc.conf
# tools

RUN yum -y install \
        wget \
        gcc \
        make \
        autoconf \
        libxml2 \
        libxml2-devel \
        openssl \
        openssl-devel \
        curl \
        curl-devel \
        pcre \
        libjpeg-devel \
        freetype-devel \
        libpng-devel \
        pcre-devel \
        libxslt \
        libxslt-devel \
        bzip2 \
        bzip2-devel \
        libedit \
        libedit-devel \
        glibc-headers \
        gcc-c++ \
    && rm -rf /var/cache/{yum,ldconfig}/* \
    && rm -rf /etc/ld.so.cache \
    && yum clean all

 #lpng1637
ADD install/re2c-0.16.tar.gz ${SRC_DIR}/

RUN cd ${SRC_DIR}/re2c-0.16 \
    && ./configure \
    && make clean > /dev/null \
    && make \
    && make install \
    && rm -f ${SRC_DIR}/re2c-0.16.tar.gz \
    && rm -rf ${SRC_DIR}/re2c-0.16


#安装gd依赖库安装
 #
 #lpng1637
ADD install/libpng-1.6.37.tar.gz ${SRC_DIR}/

RUN cd ${SRC_DIR}/libpng-1.6.37 \
    && ./configure --prefix=/usr/local/libpng \
    && make clean > /dev/null \
    && make \
    && make install \
    && rm -f ${SRC_DIR}/libpng-1.6.37.tar.gz \
    && rm -rf ${SRC_DIR}/libpng-1.6.37

 #
 #freetype
ADD install/freetype-2.4.0.tar.gz ${SRC_DIR}/

RUN cd ${SRC_DIR}/freetype-2.4.0 \
    && ./configure --prefix=/usr/local/freetype \
    && make clean > /dev/null \
    && make \
    && make install \
    && rm -f ${SRC_DIR}/freetype-2.4.0.tar.gz \
    && rm -rf ${SRC_DIR}/freetype-2.4.0

 #jpegsrc.v9
ADD install/jpegsrc.v9.tar.gz ${SRC_DIR}/

RUN cd ${SRC_DIR}/jpeg-9 \
    && ./configure --prefix=/usr/local/jpeg \
    && make clean > /dev/null \
    && make \
    && make install \
    && rm -f ${SRC_DIR}/jpegsrc.v9.tar.gz \
    && rm -rf ${SRC_DIR}/jpeg-9

 #lpng1637
ADD install/libgd-2.2.5.tar.gz ${SRC_DIR}/

RUN cd ${SRC_DIR}/libgd-2.2.5 \
    && ./configure --prefix=/usr/local/gd2   --with-jpeg=/usr/local/jpeg --with-freetype=/usr/local/freetype --with-png=/usr/local/png \
    && make clean > /dev/null \
    && make \
    && make install \
    && rm -f ${SRC_DIR}/libgd-2.2.5.tar.gz \
    && rm -rf ${SRC_DIR}/libgd-2.2.5

# php
ADD install/php-${PHP_VERSION}.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/php-${PHP_VERSION} \
    && ln -s /usr/lib64/libssl.so /usr/lib \
    && ./configure --prefix=${PHP_DIR} \
        --with-config-file-path=${PHP_INI_DIR} \
       	--with-config-file-scan-dir="${PHP_INI_DIR}/conf.d" \
       --disable-cgi \
       --enable-bcmath \
       --enable-mbstring \
       --enable-mysqlnd \
       --enable-opcache \
       --enable-pcntl \
       --enable-xml \
       --enable-zip \
       --with-curl \
       --with-libedit \
       --with-openssl \
       --with-zlib \
       --with-curl \
       --with-mysqli \
       --with-pdo-mysql \
       --with-pear \
       --with-zlib \
    && make clean > /dev/null \
    && make \
    && make install \
    && ln -s ${PHP_DIR}/bin/php /usr/local/bin/ \
    && ln -s ${PHP_DIR}/bin/phpize /usr/local/bin/ \
    && ln -s ${PHP_DIR}/bin/pecl /usr/local/bin/ \
    && ln -s ${PHP_DIR}/bin/php-config /usr/local/bin/ \
    && mkdir -p ${PHP_INI_DIR}/conf.d \
    && cp ${SRC_DIR}/php-${PHP_VERSION}/php.ini-production ${PHP_INI_DIR}/php.ini \
    && echo -e "opcache.enable=1\nopcache.enable_cli=1\nzend_extension=opcache.so" > ${PHP_INI_DIR}/conf.d/10-opcache.ini \

    && cd ${SRC_DIR}/php-${PHP_VERSION}/ext/gd \
    && phpize \
    && ./configure --with-jpeg-dir=/usr/local/jpeg --with-png-dir=/usr/local/png  --with-freetype-dir=/usr/local/freetype \
    && make \
    && make install \
    && rm -f ${SRC_DIR}/gd.tar.gz \
    && rm -rf ${SRC_DIR}/gd \
    && echo "extension=gd.so" > ${INIT_FILE}/gd.ini \
    && rm -f ${SRC_DIR}/php-${PHP_VERSION}.tar.gz \
    && rm -rf ${SRC_DIR}/php-${PHP_VERSION}

#  hiredis
ADD install/hiredis-${HIREDIS_VERSION}.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/hiredis-${HIREDIS_VERSION} \
    && make clean > /dev/null \
    && make \
    && make install \
    && ldconfig \
    && rm -f ${SRC_DIR}/hiredis-${HIREDIS_VERSION}.tar.gz \
    && rm -rf ${SRC_DIR}/hiredis-${HIREDIS_VERSION}
#  swoole
ADD install/swoole-${SWOOLE_VERSION}.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/swoole-${SWOOLE_VERSION} \
    && phpize \
    && ./configure --enable-async-redis --enable-openssl --enable-mysqlnd --enable-coroutine \
    && make clean > /dev/null \
    && make \
    && make install \
    && echo "extension=swoole.so" > ${INIT_FILE}/swoole.ini \
    && rm -f ${SRC_DIR}/swoole-${SWOOLE_VERSION}.tar.gz \
    && rm -rf ${SRC_DIR}/swoole-${SWOOLE_VERSION}

#  redis
ADD install/redis-${PHPREDIS_VERSION}.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/phpredis-${PHPREDIS_VERSION} \
    && phpize \
    && ./configure \
    && make clean > /dev/null \
    && make \
    && make install \
    && echo "extension=redis.so" > ${INIT_FILE}/redis.ini \
    && rm -f ${SRC_DIR}/redis-${PHPREDIS_VERSION}.tar.gz \
    && rm -rf ${SRC_DIR}/phpredis-${PHPREDIS_VERSION}


#  ds
ADD install/ds-${PHPDS_VERSION}.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/extension-${PHPDS_VERSION} \
    && phpize \
    && ./configure \
    && make clean > /dev/null \
    && make \
    && make install \
    && echo "extension=ds.so" > ${INIT_FILE}/ds.ini \
    && rm -f ${SRC_DIR}/ds-${PHPDS_VERSION}.tar.gz \
    && rm -rf ${SRC_DIR}/extension-${PHPDS_VERSION}


#  inotify
ADD install/inotify-${PHPINOTIFY_VERSION}.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/php-inotify-${PHPINOTIFY_VERSION} \
    && phpize \
    && ./configure \
    && make clean > /dev/null \
    && make \
    && make install \
    && echo "extension=inotify.so" > ${INIT_FILE}/inotify.ini \
    && rm -f ${SRC_DIR}/inotify-${PHPINOTIFY_VERSION}.tar.gz \
    && rm -rf ${SRC_DIR}/php-inotify-${PHPINOTIFY_VERSION}

#  ext-async
ADD install/ext-async-master.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/ext-async-master \
    && phpize \
    && ./configure  --enable-async-redis --enable-openssl --enable-mysqlnd --enable-coroutine \
    && make clean > /dev/null \
    && make -j 4 \
    && make install \
    && echo "extension=swoole_async.so" > ${INIT_FILE}/swoole_async.ini \
    && rm -f ${SRC_DIR}/ext-async-master.tar.gz \
    && rm -rf ${SRC_DIR}/ext-async-master
RUN sed -i 's|;date.timezone =|date.timezone = "Asia/Shanghai"|g' ${PHP_INI_DIR}/php.ini
RUN sed -i 's|memory_limit = 128M|memory_limit = 2048M|g' ${PHP_INI_DIR}/php.ini
RUN sed -i 's|max_execution_time = 30|max_execution_time = 300|g' ${PHP_INI_DIR}/php.ini
RUN sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 256M|g' ${PHP_INI_DIR}/php.ini
RUN sed -i 's|post_max_size = 8M|post_max_size = 256M|g' ${PHP_INI_DIR}/php.ini
COPY ./config/* ${INIT_FILE}/
