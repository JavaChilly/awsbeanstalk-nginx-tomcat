#!/bin/bash
exec > >(tee -a /var/log/nginx-eb.log|logger -t [nginx-eb] -s 2>/dev/console) 2>&1
set -ex

if [ -f /etc/init.d/httpd ]; then
yum -y remove httpd httpd-tools
yum -y install nginx
/sbin/chkconfig nginx on
fi

if [ -f /etc/nginx/conf.d/default.conf ]; then
  mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.off
fi
pwd -P
cp .ebextensions/nginx/*.conf /etc/nginx/conf.d/

if ps ax | grep -v grep | grep 'nginx' > /dev/null
then
echo "RESTARTING nginx"
/etc/init.d/nginx restart
else
echo "STARTING nginx"
/etc/init.d/nginx start
fi

sed -i 's;/var/run/httpd/httpd.pid;/var/run/nginx.pid;' /opt/elasticbeanstalk/containerfiles/tomcat.pill
sed -i 's;httpd;nginx;g' /opt/elasticbeanstalk/containerfiles/tomcat.pill
/usr/bin/bluepill load /opt/elasticbeanstalk/containerfiles/tomcat.pill