#!/usr/bin/env sh

if [ ! -d /var/lib/mysql/mysql ]; then
    echo 'Rebuilding mysql data dir'

    chown -R mysql:mysql /var/lib/mysql
    mysql_install_db > /dev/null

    rm -rf /var/run/mysqld/*

    echo 'Starting mysqld'
    # The sleep 1 is there to make sure that inotifywait starts up before the socket is created
    mysqld_safe &

    echo 'Waiting for mysqld to come online'
    while [ ! -x /var/run/mysqld/mysqld.sock ]; do
        sleep 1
    done

    echo 'Setting root password'
    /usr/bin/mysqladmin -u root password '${PERCONA_ADMIN_PASSWORD}'

    mysql -u root --password=${PERCONA_ADMIN_PASSWORD} -e "UPDATE mysql.user SET Password=PASSWORD('${PERCONA_ADMIN_PASSWORD}') WHERE User='root'"
    mysql -u root --password=${PERCONA_ADMIN_PASSWORD} -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
    mysql -u root --password=${PERCONA_ADMIN_PASSWORD} -e "DELETE FROM mysql.user WHERE User=''"
    mysql -u root --password=${PERCONA_ADMIN_PASSWORD} -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
    mysql -u root --password=${PERCONA_ADMIN_PASSWORD} -e "FLUSH PRIVILEGES"

    echo "GRANT ALL ON *.* TO admin@'%' IDENTIFIED BY '${PERCONA_ADMIN_PASSWORD}' WITH GRANT OPTION; FLUSH PRIVILEGES;" | mysql -u root --password=${PERCONA_ADMIN_PASSWORD}

    echo 'Shutting down mysqld'
    mysqladmin -u root --password=${PERCONA_ADMIN_PASSWORD} shutdown
    sleep 10
fi

cp /etc/mysql/conf/my.cnf /etc/mysql/my.cnf
chmod 644 /etc/mysql/my.cnf

mysqld_safe &
