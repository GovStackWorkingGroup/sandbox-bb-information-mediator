#!/bin/bash

# Update X-Road configuration on startup, if necessary
INSTALLED_VERSION=$(dpkg-query --showformat='${Version}' --show xroad-center)
PACKAGED_VERSION="$(cat /root/VERSION)"

if [ "$INSTALLED_VERSION" == "$PACKAGED_VERSION" ]; then
    if [ -f /etc/xroad/VERSION ]; then
        CONFIG_VERSION="$(cat /etc/xroad/VERSION)"
    else
        echo "WARN: Current configuration version not known" >&2
        CONFIG_VERSION=
    fi
    if [ -n "$CONFIG_VERSION" ] && dpkg --compare-versions "$PACKAGED_VERSION" gt "$CONFIG_VERSION"; then
        echo "Updating configuration from $CONFIG_VERSION to $PACKAGED_VERSION"
        cp -a /root/etc/xroad/* /etc/xroad/
        pg_ctlcluster 14 main start
        pg_isready -t 14
        apt-get -qq update
        apt-get -qq install xroad-database-remote
        apt-get -qq clean        
        dpkg-reconfigure xroad-center
        pg_ctlcluster 14 main stop
        nginx -s stop
        sleep 1
        echo "$PACKAGED_VERSION" >/etc/xroad/version
    fi
    if [ ! -f /home/ca/CA/.init ]; then
        echo "Initializing TEST-CA"
        su ca -c 'cd /home/ca/CA && ./init.sh'
    fi
else
    echo "WARN: Installed version ($INSTALLED_VERSION) does not match packaged version ($PACKAGED_VERSION)" >&2
fi

if [  -n "$XROAD_TOKEN_PIN" ]
then
    echo "XROAD_TOKEN_PIN variable set, writing to /etc/xroad/autologin"
    echo "$XROAD_TOKEN_PIN" > /etc/xroad/autologin
    unset XROAD_TOKEN_PIN
fi


XROAD_PROPERTIES="/etc/xroad.properties"
DB_PROPERTIES="/etc/xroad/db.properties"
CENTERUI_SQL="/etc/xroad/centerui.sql"
PG_DUMP="/etc/xroad/centerui_production.sql"

touch /etc/xroad.properties && chown root:root $XROAD_PROPERTIES && chmod 600 $XROAD_PROPERTIES
chown xroad:xroad /etc/xroad && chmod 751 /etc/xroad && touch $DB_PROPERTIES
chmod 0640 $DB_PROPERTIES && chown xroad:xroad $DB_PROPERTIES
touch $CENTERUI_SQL && chmod 0640 $CENTERUI_SQL && chown xroad:xroad $CENTERUI_SQL

echo "postgres.connection.password = $DB_ADMIN_PASS" > $XROAD_PROPERTIES
echo "postgres.connection.user = $DB_ADMIN_USER" >> $XROAD_PROPERTIES

echo "adapter=postgresql" > $DB_PROPERTIES
echo "encoding=utf8" >> $DB_PROPERTIES
echo "username=centerui" >> $DB_PROPERTIES
echo "password=$DB_UI_PASS" >> $DB_PROPERTIES
echo "database=centerui_production" >> $DB_PROPERTIES
echo "schema=centerui" >> $DB_PROPERTIES
echo "reconnect=true" >> $DB_PROPERTIES
echo "host=$DB_HOST" >> $DB_PROPERTIES
echo "port=$DB_PORT" >> $DB_PROPERTIES
echo "skip_migrations=false" >> $DB_PROPERTIES

echo "CREATE DATABASE centerui_production ENCODING 'UTF8';" > $CENTERUI_SQL
echo "REVOKE ALL ON DATABASE centerui_production FROM PUBLIC;" >> $CENTERUI_SQL
echo "CREATE ROLE centerui LOGIN PASSWORD '$DB_UI_PASS';" >> $CENTERUI_SQL
echo "GRANT centerui to $DB_ADMIN_USER;" >> $CENTERUI_SQL
echo "GRANT CREATE,TEMPORARY,CONNECT ON DATABASE centerui_production TO centerui;" >> $CENTERUI_SQL
echo "\c centerui_production" >> $CENTERUI_SQL
echo "CREATE EXTENSION hstore;" >> $CENTERUI_SQL
echo "CREATE SCHEMA centerui AUTHORIZATION centerui;" >> $CENTERUI_SQL
echo "REVOKE ALL ON SCHEMA public FROM PUBLIC;" >> $CENTERUI_SQL
echo "GRANT USAGE ON SCHEMA public to centerui;" >> $CENTERUI_SQL

export PGPASSWORD=$DB_ADMIN_PASS
psql -h $DB_HOST -U $DB_ADMIN_USER -f $CENTERUI_SQL
psql -h $DB_HOST -p $DB_PORT -U $DB_ADMIN_USER centerui_production < $PG_DUMP
supervisorctl stop postgres
supervisorctl restart xroad-jetty && supervisorctl restart xroad-signer

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf

