# Use phusion/baseimage as base image.
FROM phusion/baseimage:0.9.18

MAINTAINER Masood Ahmed masood.ahmed09@gmail.com

# Set correct environment variables.
ENV HOME /root

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Regenerate SSH host keys. baseimage-docker does not contain any, so we
# have to do that yourself.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

ENV DEBIAN_FRONTEND noninteractive

# Gerenare the locales
RUN locale-gen en_US.UTF-8
RUN export LANG=en_US.UTF-8

# Add Percona repositories
RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
RUN echo "deb http://repo.percona.com/apt trusty main" >> /etc/apt/sources.list
RUN echo "deb-src http://repo.percona.com/apt trusty main" >> /etc/apt/sources.list
RUN touch /etc/apt/preferences.d/00percona.pref
RUN echo "Package: *" >> /etc/apt/preferences.d/00percona.pref
RUN echo "Pin: release o=Percona Development Team" >> /etc/apt/preferences.d/00percona.pref
RUN echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/00percona.pref

# Update & upgrade the repositories
RUN apt-get update
RUN apt-get -y --force-yes upgrade

# Install Percona (5.6.29-76.2-1)
RUN apt-get install -y --force-yes percona-server-server

# Remove the database dir
RUN rm -rf /var/lib/mysql
RUN mkdir /var/lib/mysql
RUN chown mysql:mysql /var/lib/mysql

# Copy the init files for Mailcacher
ADD build/99_percona.sh /etc/my_init.d/99_percona.sh
RUN chmod +x /etc/my_init.d/99_percona.sh

# Make the port 6379 available to outside world
EXPOSE 3306

# Deleting the man pages and documentation
RUN find /usr/share/doc -depth -type f ! -name copyright|xargs rm || true
RUN find /usr/share/doc -empty|xargs rmdir || true
RUN rm -rf /usr/share/man /usr/share/groff /usr/share/info /usr/share/lintian > /usr/share/linda /var/cache/man

# Clean up APT when done.
RUN apt-get clean
RUN apt-get autoclean
RUN apt-get autoremove
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
