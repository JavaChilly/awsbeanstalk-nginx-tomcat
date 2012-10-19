#!/bin/sh
# IMPORTANT: Run this script as sudo or else it won't work
# Original script: http://my.safaribooksonline.com/book/programming/java/9781449309558/hacking-elastic-beanstalk/hackingelectric#X2ludGVybmFsX0ZsYXNoUmVhZGVyP3htbGlkPTk3ODE0NDkzMDk1NTgvSV9zZWN0MTRfZDFlMjAyNQ==

if [ ! -f /etc/nginx/nginx.conf ];
then

echo 'Installing nginx...sit tight'
yum -y install nginx

echo 'Fixing nginx configuration'
sed -i 's/ 1;/ 4;/g' /etc/nginx/nginx.conf
rm /etc/nginx/conf.d/default.conf

echo 'Messing around with hostmanager so nginx works with it'
sed -i 's/httpd/nginx/g' /opt/elasticbeanstalk/containerfiles/tomcat.pill
sed -i 's/var\/run\/nginx/var\/run/g' /opt/elasticbeanstalk/containerfiles/tomcat.pill

echo 'Creating configuration files'
echo 'proxy_redirect            off;
proxy_set_header          Host            $host;
proxy_set_header          X-Real-IP       $remote_addr;
proxy_set_header          X-Forwarded-For $proxy_add_x_forwarded_for;
client_max_body_size      10m;
client_body_buffer_size   128k;
client_header_buffer_size 64k;
proxy_connect_timeout     90;
proxy_send_timeout        90;
proxy_read_timeout        90;
proxy_buffer_size         16k;
proxy_buffers             32              16k;
proxy_busy_buffers_size   64k;' > /etc/nginx/conf.d/proxy.conf

echo 'server {
 listen 80;
 server_name _;
 access_log /var/log/httpd/elasticbeanstalk-access_log;
 error_log /var/log/httpd/elasticbeanstalk-error_log;

 #set the default location
 location / {
  proxy_pass         http://127.0.0.1:8080/;
 }

 # make sure the hostmanager works
 location /_hostmanager/ {
  proxy_pass         http://127.0.0.1:8999/;
 }
}' > /etc/nginx/conf.d/beanstalk.conf

echo 'Making sure that nginx starts on startup'
/sbin/chkconfig nginx on

echo 'Starting nginx'
service nginx start

echo 'Removing Apache...no longer needed'
yum -y remove httpd

echo 'Done'

fi