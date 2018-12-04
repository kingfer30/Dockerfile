#!/bin/sh
#########################################################################
# File Name: start.sh
# Author: kingfer
# Email:  kingfer30@qq.com
# Version:
# Created Time: 2017/11/30
#########################################################################
Nginx_Install_Dir=/usr/local/nginx
DATA_DIR=/acs/code
PORT=`cat /acs/conf/env.properties |grep -w port.slbhttps0 |awk -F "=" '{print $2}'`
     if [ ! $PORT ]; then
        PORT=80
     fi
INCLUDE=''
     if [ -f "/usr/local/nginx/conf/include.conf" ]; then
        INCLUDE='include include.conf;'
     fi
set -e

cat > ${Nginx_Install_Dir}/conf/nginx.conf << EOF
user  root;
worker_processes auto;
 

pid /var/run/nginx.pid;
worker_rlimit_nofile 10240;

events {
    use epoll;
    worker_connections 10240;
    multi_accept on;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

	include fastcgi.conf;
	limit_conn_zone \$binary_remote_addr zone=arbeit:10m;

    sendfile        on;
    client_max_body_size 100m;  
    keepalive_timeout  120;

	gzip  on; 
    gzip_buffers      16 8k; 
    gzip_comp_level   1;  
    gzip_http_version 1.1;
    gzip_min_length   10; 
    gzip_types        text/plain text/css application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript image/x-icon application/vnd.ms-fontobject font/opentype application/x-font-ttf;
    gzip_vary         on; 
    gzip_proxied      any; 
    gzip_disable "msie6";
    server_tokens off;

    server {
        listen $PORT backlog=2048;
        server_name  localhost;
        root   $root;
        index  index.php index.html index.htm;

        $INCLUDE

        access_log off;
        error_log /acs/environment/nginx.err.log error;

		location ~ [^/]\.php(/|$) {
        	try_files \$uri =404;
        	fastcgi_pass  unix:/var/tmp/php-fpm.sock;
        	fastcgi_index index.php;
    
        	fastcgi_param  SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
        	fastcgi_param  QUERY_STRING       \$query_string;
        	fastcgi_param  REQUEST_METHOD     \$request_method;
        	fastcgi_param  CONTENT_TYPE       \$content_type;
        	fastcgi_param  CONTENT_LENGTH     \$content_length;
    
        	fastcgi_param  SCRIPT_NAME        \$fastcgi_script_name;
        	fastcgi_param  REQUEST_URI        \$request_uri;
        	fastcgi_param  DOCUMENT_URI       \$document_uri;
        	fastcgi_param  DOCUMENT_ROOT      \$document_root;
        	fastcgi_param  SERVER_PROTOCOL    \$server_protocol;
        	fastcgi_param  HTTPS              \$https if_not_empty;
    
        	fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
        	fastcgi_param  SERVER_SOFTWARE    nginx/\$nginx_version;
    
        	fastcgi_param  REMOTE_ADDR        \$remote_addr;
        	fastcgi_param  REMOTE_PORT        \$remote_port;
        	fastcgi_param  SERVER_ADDR        \$server_addr;
        	fastcgi_param  SERVER_PORT        \$server_port;
        	fastcgi_param  SERVER_NAME        \$server_name;
    
        	# PHP only, required if PHP was built with --enable-force-cgi-redirect
        	fastcgi_param  REDIRECT_STATUS    200;
    
			#设置PATH_INFO并改写SCRIPT_FILENAME,SCRIPT_NAME服务器环境变量

        	set \$fastcgi_script_name2 \$fastcgi_script_name;
        	if (\$fastcgi_script_name ~ "^(.+\\.php)(/.+)$") {
        	        set \$fastcgi_script_name2 \$1; 
        	        set \$path_info \$2; 
        	}   
        	fastcgi_param   PATH_INFO \$path_info;
        	fastcgi_param   SCRIPT_FILENAME   \$document_root\$fastcgi_script_name2;
        	fastcgi_param   SCRIPT_NAME   \$fastcgi_script_name2;
    	}   
    }
}
daemon off;
EOF

/usr/bin/supervisord -n -c /etc/supervisord.conf
