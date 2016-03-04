FROM ubuntu:latest
MAINTAINER Justin Toler <jwtoler@gmail.com>

# Configure locales
RUN locale-gen en_US en_US.UTF-8
RUN dpkg-reconfigure locales

# Get updates and perform upgrade
RUN apt-get update
RUN apt-get -y upgrade

# Install apache, PHP, and supplimentary programs. curl and lynx-cur are for debugging the container.
RUN DEBIAN_FRONTEND=noninteractive 
RUN apt-get -y install apache2 libapache2-mod-php5 php5-mysql php5-ldap php5-gd php5-xsl php-pear php-apc php5-curl php5-xmlrpc php5-intl curl lynx-cur

# Enable apache mods.
RUN a2enmod php5
RUN a2enmod rewrite

#Enviornment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php5/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Copy default/generic site into place.
#ADD www /var/www/html

# SSL Configurations
RUN sed -i 's/^ServerSignature/#ServerSignature/g' /etc/apache2/conf-enabled/security.conf; \
    sed -i 's/^ServerTokens/#ServerTokens/g' /etc/apache2/conf-enabled/security.conf; \
    echo "ServerSignature Off" >> /etc/apache2/conf-enabled/security.conf; \
    echo "ServerTokens Prod" >> /etc/apache2/conf-enabled/security.conf; \
    a2enmod ssl; \
    a2enmod headers; \
    echo "SSLProtocol ALL -SSLv2 -SSLv3" >> /etc/apache2/apache2.conf

# Generate Self Signed SSL
RUN mkdir -p /etc/apache2/ssl
RUN openssl req -x509 -newkey rsa:4086 \
  -subj "/C=XX/ST=XXXX/L=XXXX/O=XXXX/CN=local.lajolla" \
  -keyout "/etc/apache2/ssl/key.pem" \
  -out "/etc/apache2/ssl/cert.pem" \
  -days 3650 -nodes -sha256

# Update the default apache site with the config we created for non-ssl & ssl
ADD apache_default /etc/apache2/sites-enabled/000-default.conf
ADD apache_default_ssl /etc/apache2/sites-enabled/000-default-ssl.conf
ADD ports_default /etc/apache2/ports.conf

# Install PrinceXML
RUN wget http://www.princexml.com/download/prince_10r7-1_ubuntu14.04_amd64.deb -O /
RUN aptitude install gdebi
RUN gdebi prince_10r7-1_ubuntu14.04_amd64.deb

EXPOSE 80
EXPOSE 443

# Start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND
