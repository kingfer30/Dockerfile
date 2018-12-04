FROM registry.acs.aliyun.com/yunjf/centos:latest
MAINTAINER KingFer <kingfer30@qq.com>

ENV NGINX_VERSION 1.11.6
ENV PHP_VERSION 7.0.7

RUN yum install -y gcc \
    gcc-c++ \
    autoconf \
    automake \
    libtool \
    make \
    cmake && \
    yum clean all

#安装PHP扩展
## libmcrypt-devel DIY
RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm && \
    yum install -y wget \
    zlib \
    zlib-devel \
    openssl \
    openssl-devel \
    pcre-devel \
    libxml2 \
    libxml2-devel \
    libcurl \
    libcurl-devel \
    libpng-devel \
    libjpeg-devel \
    freetype-devel \
    libmcrypt-devel \
    openssh-server \
    python-setuptools && \
    yum clean all

#下载nginx和php和redis扩展
RUN mkdir -p /home/nginx-php && cd $_ && \
    wget -c -O nginx.tar.gz http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    wget -O php.tar.gz http://php.net/distributions/php-$PHP_VERSION.tar.gz && \
    wget -c https://github.com/phpredis/phpredis/archive/php7-ipv6.zip


#安装Nginx
RUN cd /home/nginx-php && \
    tar -zxvf nginx.tar.gz && \
    cd nginx-$NGINX_VERSION && \
    ./configure --prefix=/usr/local/nginx \
    --with-pcre \
    --with-http_ssl_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --with-http_gzip_static_module && \
    make && make install

#安装 php
RUN cd /home/nginx-php && \
    tar zvxf php.tar.gz && \
    cd php-$PHP_VERSION && \
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/etc/php.d \
    --with-mcrypt=/usr/include \
    --with-mysqli \
    --with-pdo-mysql \
    --with-openssl \
    --with-gd \
    --with-iconv \
    --with-zlib \
    --with-gettext \
    --with-curl \
    --with-png-dir \
    --with-jpeg-dir \
    --with-freetype-dir \
    --with-xmlrpc \
    --with-mhash \
    --enable-fpm \
    --enable-xml \
    --enable-shmop \
    --enable-sysvsem \
    --enable-inline-optimization \
    --enable-mbregex \
    --enable-mbstring \
    --enable-ftp \
    --enable-gd-native-ttf \
    --enable-mysqlnd \
    --enable-pcntl \
    --enable-sockets \
    --enable-zip \
    --enable-soap \
    --enable-session \
    --enable-opcache \
    --enable-bcmath \
    --enable-exif \
    --enable-fileinfo \
    --disable-rpath \
    --enable-ipv6 \
    --disable-debug \
    --without-pear && \
    make && make install


# 添加redis扩展
RUN cd /home/nginx-php && \
    unzip php7-ipv6.zip && \
    cd /home/nginx-php/phpredis-php7-ipv6 && \
    /usr/local/php/bin/phpize && \
    ./configure --with-php-config=/usr/local/php/bin/php-config && \
    make && make install

#安装 supervisor 用于管理启动nginx\php进程
RUN easy_install supervisor && \
    mkdir -p /var/log/supervisor && \
    mkdir -p /var/run/sshd && \
    mkdir -p /var/run/supervisord
    
#自定义添加php.ini和php-fpm.conf
ADD php.ini /usr/local/php/etc/php.ini
ADD php-fpm.conf /usr/local/php/etc/php-fpm.conf

#添加 supervisord conf
ADD supervisord.conf /etc/supervisord.conf

#添加wkhtmltopdf
RUN cd /home/nginx-php && \
wget -c http://ewspublish.api.enbrands.com:81/wkhtmltox.tar.xz && \
tar xvf wkhtmltox.tar.xz && \
mv wkhtmltox/bin/wkhtmlto* /usr/bin/ && \
chmod +x /usr/bin/wkhtmlto*  && \
yum -y install libXrender* && \
ln -s /usr/bin/wkhtmlto* /usr/local/bin/ 

#添加字体
ADD fonts/simsun.ttc /usr/share/fonts/simsun.ttc

#移除安装包
RUN cd / && rm -rf /home/nginx-php

#添加启动命令
COPY start.sh /acs/bin/start
RUN chmod +x /acs/bin/start

#设置端口
EXPOSE 80 443

#开始启动
ENTRYPOINT ["/acs/bin/start"]

#启动站点
#CMD ["/bin/bash", "/acs/bin/start"]
