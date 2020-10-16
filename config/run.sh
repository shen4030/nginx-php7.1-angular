#!/bin/bash

set -euo pipefail

sed -i -e "s/error_reporting =.*=/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/g" /etc/php/7.1/fpm/php.ini
sed -i -e "s/display_errors =.*/display_errors = Off/g" /etc/php/7.1/fpm/php.ini

procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s/worker_processes 5/worker_processes $procs/" /etc/nginx/nginx.conf

set +e 
chown -Rf www-data.www-data /var/www
set -e

/usr/bin/supervisord -n -c /etc/supervisord.conf