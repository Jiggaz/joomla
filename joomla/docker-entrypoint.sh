#!/bin/bash

set -e

HOST=`hostname`
        NAME=`echo $HOST | sed 's:.*-::'`
#        sed -i "s/{DB_HOSTNAME}/$NAME/g" /install.sh

if [[ -f "$JOOMLA_DB_PASSWORD_FILE" ]]; then
        DB_PASSWORD=$(cat "$JOOMLA_DB_PASSWORD_FILE")
fi

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
        if [ -n "{MYSQL_PORT_3306_TCP}" ]; then
                if [ -z "$JOOMLA_DB_HOST" ]; then
                        JOOMLA_DB_HOST="mariadb-$NAME"
                else
                        echo >&2 "warning: both JOOMLA_DB_HOST and MYSQL_PORT_3306_TCP found"
                        echo >&2 "  Connecting to JOOMLA_DB_HOST ({JOOMLA_DB_HOST})"
                        echo >&2 "  instead of the linked mysql container"
                fi
        fi

        if [ -z "$JOOMLA_DB_HOST" ]; then
                echo >&2 "error: missing JOOMLA_DB_HOST and MYSQL_PORT_3306_TCP environment variables"
                echo >&2 "  Did you forget to --link some_mysql_container:mysql or set an external db"
                echo >&2 "  with -e JOOMLA_DB_HOST=hostname:port?"
                exit 1
        fi

        # If the DB user is 'root' then use the MySQL root password env var
        : ${JOOMLA_DB_USER:={JOOMLA_DB_USER}}
        if [ "$JOOMLA_DB_USER" = '{JOOMLA_DB_USER}' ]; then
                : ${JOOMLA_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
        fi
        : ${JOOMLA_DB_NAME:={JOOMLA_DB_NAME}}

        if [ -z "{JOOMLA_DB_PASSWORD}" ] && [ "$DB_PASSWORD_ALLOW_EMPTY" != 'yes' ]; then
                echo >&2 "error: missing required JOOMLA_DB_PASSWORD environment variable"
                echo >&2 "  Did you forget to -e JOOMLA_DB_PASSWORD=... ?"
                echo >&2
                echo >&2 "  (Also of interest might be JOOMLA_DB_USER and JOOMLA_DB_NAME.)"
                exit 1
        fi

        if ! [ -e index.php -a \( -e libraries/cms/version/version.php -o -e libraries/src/Version.php \) ]; then
                echo >&2 "Joomla not found in $(pwd) - copying now..."

                if [ "$(ls -A)" ]; then
                        echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
                        ( set -x; ls -A; sleep 10 )
                fi

                tar cf - --one-file-system -C /usr/src/joomla . | tar xf - 2> /dev/null

                if [ ! -e .htaccess ]; then
                        # NOTE: The "Indexes" option is disabled in the php:apache base image so remove it as we enable .htaccess
                        sed -r 's/^(Options -Indexes.*)$/#\1/' htaccess.txt > .htaccess
                        # if [[ {BACK_END} = nginx ]]  ;
                        # then
                        #     chown -R apache:apache /var/www
                        #     chown apache:apache .htaccess
                        #     chmod -R 777 installation
                        # else
                        #     chmod -R nobody:nobody /var/www
                        #     chown nginx:nginx .htaccess
                        #     chmod -R 777 installation
                        # fi
                fi

                echo >&2 "Complete! Joomla has been successfully copied to $(pwd)"
        fi

        # Ensure the MySQL Database is created
        php /makedb.php "{JOOMLA_DB_HOST}" "{JOOMLA_DB_USER}" "{JOOMLA_DB_PASSWORD}" "{JOOMLA_DB_NAME}"

        echo >&2 "========================================================================"
        echo >&2
        echo >&2 "This server is now configured to run Joomla!"
        echo >&2
        echo >&2 "NOTE: You will need your database server address, database name,"
        echo >&2 "and database user credentials to install Joomla."
        echo >&2
        echo >&2 "========================================================================"
fi

rm -rf /var/preview
if [[ {BACK_END} = nginx ]]  ; 
then
    cp /app/default.conf /etc/nginx/conf.d/default.conf
    nginx -s reload
    chown -R nobody:nobody /var/www 2> /dev/null
else
    cp /app/httpd.conf /etc/apache2/httpd.conf
    httpd -k graceful
    chown -R apache:apache /var/www 2> /dev/null
fi

rm -rf /var/preview
rm -rf /app/default.conf
exec "$@"