FROM ubuntu:16.04

COPY ./config/run.sh /
RUN chmod 755 /run.sh

# 准备
RUN dpkg-divert --local --rename --add /sbin/initctl && \
	ln -sf /bin/true /sbin/initctl && \
	mkdir /var/run/sshd && \
	mkdir /run/php && \
	apt-get update && \
	apt-get install -y --no-install-recommends apt-utils \ 
		software-properties-common \
		python-software-properties \
		language-pack-en-base && \
	LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php

# 安装nginx，supervisor
RUN	apt-get update && apt-get upgrade -y && apt-get install -y python-setuptools \ 
		apt-utils \
		curl \
		git \
		unzip \
		sudo \
		openssh-server \
		openssl \
		nginx \
		ssmtp \
		cron \
		supervisor

# 安装PHP及相关拓展
RUN	apt-get install -y php7.1-fpm \
	php7.1-mysql \
	php7.1-curl \
	php7.1-gd \
	php7.1-intl \
	php7.1-mcrypt \
	php7.1-sqlite \
	php7.1-tidy \
	php7.1-xmlrpc \
	php7.1-pgsql \
	php7.1-ldap \
	php7.1-sqlite3 \
	php7.1-json \
	php7.1-xml \
	php7.1-mbstring \
	php7.1-soap \
	php7.1-zip \
	php7.1-cli \
	php7.1-sybase \
	php7.1-odbc \
	php7.1-yaml \
	php7.1-redis \
	php7.1-mongodb \
	php7.1-bcmath \
	php7.1-simplexml

# 安装node
RUN apt-get install -y nodejs \
	nodejs-legacy \
	npm

# PHP-FPM配置
RUN	sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.1/fpm/php.ini && \
	sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.1/fpm/php.ini && \
	sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.1/fpm/php.ini && \
	sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf && \
	sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	sed -i -e "/pid\s*=\s*\/run/c\pid = /run/php7.1-fpm.pid" /etc/php/7.1/fpm/php-fpm.conf && \
	sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.1/fpm/pool.d/www.conf
	
# 安装angular/cli
RUN npm config set registry https://registry.npm.taobao.org
RUN npm install n -g
RUN n stable
RUN npm install -g @angular/cli

# 清理包
RUN apt-get remove --purge -y software-properties-common \
	python-software-properties && \
	apt-get autoremove -y && \
	apt-get clean && \
	apt-get autoclean

# 安装composer
RUN curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# nginx配置
COPY ./config/nginx/nginx.conf /etc/nginx/nginx.conf
RUN chown -Rf www-data.www-data /var/www 

# supervisor配置
COPY ./config/supervisor/supervisord.conf /etc/supervisord.conf

# 创建工作目录
RUN mkdir -p /var/www
COPY ./www/ /var/www

EXPOSE 80

ENTRYPOINT ["/bin/bash", "/run.sh"]

