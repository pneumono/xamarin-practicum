#!/bin/bash

if [ -e /etc/redhat-release ] && grep -q "CentOS Linux release 7" /etc/redhat-release; then
  yum install -y php php-cli php-openssl php-mysql php-curl httpd mariadb mariadb-server git expect

  systemctl enable mariadb.service
  systemctl start mariadb.service
  systemctl enable httpd.service
  systemctl start httpd.service

  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/local/bin/composer

  cd /var/www/html/
  git clone https://github.com/paypal/rest-api-sample-app-php.git .
  chown -R apache:apache

  COMPOSER_HOME=/var/www/html/.composer composer update

  mysql_root_password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
  export mysql_root_password # because expect requires variables to be global
  mysql_paypaluser_password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)

  /usr/bin/expect -c '
  set timeout 1

  spawn mysql_secure_installation
  expect "Enter current password for root (enter for none): "
  send "\r"
  expect "Change the root password? \[Y/n\] "
  send "Y\r"
  expect "New password: "
  send "$env(mysql_root_password)\r"
  expect "Re-enter new password: "
  send "$env(mysql_root_password)\r"
  expect "Remove anonymous users? \[Y/n\] "
  send "Y\r"
  expect "Disallow root login remotely? \[Y/n\] "
  send "Y\r"
  expect "Remove test database and access to it? \[Y/n\] "
  send "Y\r"
  expect "Reload privilege tables now? \[Y/n\] "
  send "Y\r" '

  mysql -uroot -p"$mysql_root_password" -e "create database paypal_pizza_app;"
  mysql -uroot -p"$mysql_root_password" -e "grant all privileges on paypal_pizza_app.* to paypal_user@localhost identified by '$mysql_paypaluser_password';"
  mysql -uroot -p"$mysql_root_password" paypal_pizza_app < install/db.sql

  sed -i "s/'MYSQL_USERNAME', 'root'/'MYSQL_USERNAME', 'paypal_user'/; s/'MYSQL_PASSWORD', 'root'/'MYSQL_PASSWORD', '$mysql_paypaluser_password'/" /var/www/html/app/bootstrap.php

  firewall-cmd --zone=public --add-service=http --permanent
  firewall-cmd --zone=public --add-service=https --permanent
  firewall-cmd --zone=public --remove-service=ssh --permanent
  firewall-cmd --permanent --zone=trusted --add-source=10.0.0.0/8
  firewall-cmd --permanent --zone=trusted --add-source=192.168.0.0/16
  firewall-cmd --permanent --zone=trusted --add-source=172.0.0.0/8
  firewall-cmd --permanent --zone=trusted --add-service ssh
  firewall-cmd --reload

  printf "mysql root password is: $mysql_root_password\n"
  unset mysql_root_password # so this isn't just hanging around in the terminal session
elif [ -e /etc/issue ] && grep -q "Ubuntu 14.04.2 LTS" /etc/issue; then
  mysql_root_password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
  mysql_paypaluser_password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)

  echo "mysql-server mysql-server/root_password select $mysql_root_password" | debconf-set-selections
  echo "mysql-server mysql-server/root_password_again select $mysql_root_password" | debconf-set-selections
  apt-get install -y php5 php5-cli php5-mysql php5-curl apache2 mysql-server git expect firewalld

  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/local/bin/composer

  cd /var/www/html/
  rm * # ubuntu leaves some stuff in here
  git clone https://github.com/paypal/rest-api-sample-app-php.git .
  chown -R www-data:www-data .

  COMPOSER_HOME=/var/www/html/.compose composer update

  mysql -uroot -p"$mysql_root_password" -e "create database paypal_pizza_app;"
  mysql -uroot -p"$mysql_root_password" -e "grant all privileges on paypal_pizza_app.* to paypal_user@localhost identified by '$mysql_paypaluser_password';"
  mysql -uroot -p"$mysql_root_password" paypal_pizza_app < install/db.sql

  sed -i "s/'MYSQL_USERNAME', 'root'/'MYSQL_USERNAME', 'paypal_user'/; s/'MYSQL_PASSWORD', 'root'/'MYSQL_PASSWORD', '$mysql_paypaluser_password'/" /var/www/html/app/bootstrap.php

  firewall-cmd --zone=public --add-service=http --permanent
  firewall-cmd --zone=public --add-service=https --permanent
  firewall-cmd --zone=public --remove-service=ssh --permanent
  firewall-cmd --permanent --zone=trusted --add-source=10.0.0.0/8
  firewall-cmd --permanent --zone=trusted --add-source=192.168.0.0/16
  firewall-cmd --permanent --zone=trusted --add-source=172.0.0.0/8
  firewall-cmd --permanent --zone=trusted --add-service ssh
  firewall-cmd --reload

  printf "mysql root password is: $mysql_root_password\n"
else
  printf "This distribution is not supported by this script.\n"
fi
