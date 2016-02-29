FROM ubuntu:latest

MAINTAINER Dan Pupius <dan@pupi.us>

# Configure locales
RUN locale-gen en_US en_US.UTF-8
RUN dpkg-reconfigure locales

# Get updates and perform upgrade
RUN apt-get update
RUN apt-get -y upgrade

# Install apache, PHP, and supplimentary programs. curl and lynx-cur are for debugging the container.
RUN DEBIAN_FRONTEND=noninteractive 
RUN apt-get -y install apache2 libapache2-mod-php5 php5-mysql php5-gd php-pear php-apc php5-curl php5-xmlrpc php5-intl curl lynx-cur

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

# Download and unpack the latest version of Moodle
#ADD https://download.moodle.org/moodle/moodle-latest.tgz /var/www/moodle-latest.tgz
#RUN cd /var/www; tar zxvf moodle-latest.tgz; mv /var/www/moodle /var/www/html
#RUN chown -R www-data:www-data /var/www/html/moodle

# Moodle Data Directory
#RUN mkdir /var/www/moodledata
#RUN chown -R www-data:www-data /var/www/moodledata;
#RUN chmod 777 /var/www/moodledata

# Copy default/generic site into place.
ADD www /var/www/html

# Update the default apache site with the config we created.
ADD apache_default /etc/apache2/sites-enabled/000-default.conf
ADD ports_default /etc/apache2/ports.conf

EXPOSE 80

# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND
