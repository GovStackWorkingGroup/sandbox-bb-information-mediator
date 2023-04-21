#!/bin/bash

# Update X-Road configuration on startup, if necessary
INSTALLED_VERSION=$(dpkg-query --showformat='${Version}' --show xroad-proxy)
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
        dpkg-reconfigure xroad-proxy xroad-signer xroad-addon-messagelog
        pg_ctlcluster 14 main stop
        sleep 1
        echo "$PACKAGED_VERSION" >/etc/xroad/version
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
  SERVERCONF_SQL="/etc/xroad/db_serverconf.sql"
  MESSAGELOG_SQL="/etc/xroad/db_messagelog.sql"
  PG_DUMP="/etc/xroad/serverconf.sql"
  PG_DUMP2="/etc/xroad/messagelog.sql"

  touch $XROAD_PROPERTIES && chown root:root $XROAD_PROPERTIES && chmod 600 $XROAD_PROPERTIES
  chown xroad:xroad /etc/xroad && chmod 751 /etc/xroad && touch $DB_PROPERTIES
  chmod 0640 $DB_PROPERTIES && chown xroad:xroad $DB_PROPERTIES
  touch $SERVERCONF_SQL && chmod 0640 $SERVERCONF_SQL && chown xroad:xroad $SERVERCONF_SQL
  touch $MESSAGELOG_SQL && chmod 0640 $MESSAGELOG_SQL && chown xroad:xroad $MESSAGELOG_SQL

  echo "postgres.connection.password = $DB_ADMIN_PASS" > $XROAD_PROPERTIES
  echo "postgres.connection.user = $DB_ADMIN_USER" >> $XROAD_PROPERTIES
  echo "serverconf.database.admin_user = serverconf_admin" >> $XROAD_PROPERTIES
  echo "serverconf.database.admin_password = $DB_SERVERCONF_ADMIN_PASS" >> $XROAD_PROPERTIES
  echo "messagelog.database.admin_user = messagelog_admin" >> $XROAD_PROPERTIES
  echo "messagelog.database.admin_password = $DB_MESSAGELOG_ADMIN_PASS" >> $XROAD_PROPERTIES

  echo "serverconf.hibernate.connection.url = jdbc:postgresql://$DB_HOST:$DB_PORT/serverconf" > $DB_PROPERTIES
  echo "serverconf.hibernate.connection.username = serverconf" >> $DB_PROPERTIES
  echo "serverconf.hibernate.connection.password = $DB_SERVERCONF_PASS" >> $DB_PROPERTIES
  echo "serverconf.hibernate.hikari.dataSource.currentSchema = serverconf,public" >> $DB_PROPERTIES
  echo "messagelog.hibernate.connection.url = jdbc:postgresql://$DB_HOST:$DB_PORT/messagelog" >> $DB_PROPERTIES
  echo "messagelog.hibernate.connection.username = messagelog" >> $DB_PROPERTIES
  echo "messagelog.hibernate.connection.password = $DB_MESSAGELOG_PASS" >> $DB_PROPERTIES
  echo "messagelog.hibernate.hikari.dataSource.currentSchema = messagelog,public" >> $DB_PROPERTIES

  echo "CREATE DATABASE serverconf ENCODING 'UTF8';" > $SERVERCONF_SQL
  echo "REVOKE ALL ON DATABASE serverconf FROM PUBLIC;" >> $SERVERCONF_SQL
  echo "CREATE ROLE serverconf_admin LOGIN PASSWORD '$DB_SERVERCONF_ADMIN_PASS';" >> $SERVERCONF_SQL
  echo "GRANT serverconf_admin to $DB_ADMIN_USER;" >> $SERVERCONF_SQL
  echo "GRANT CREATE,TEMPORARY,CONNECT ON DATABASE serverconf TO serverconf_admin;" >> $SERVERCONF_SQL
  echo "\c serverconf" >> $SERVERCONF_SQL
  echo "CREATE EXTENSION hstore;" >> $SERVERCONF_SQL
  echo "CREATE SCHEMA serverconf AUTHORIZATION serverconf_admin;" >> $SERVERCONF_SQL
  echo "REVOKE ALL ON SCHEMA public FROM PUBLIC;" >> $SERVERCONF_SQL
  echo "GRANT USAGE ON SCHEMA public to serverconf_admin;" >> $SERVERCONF_SQL
  echo "CREATE ROLE serverconf LOGIN PASSWORD '$DB_SERVERCONF_PASS';" >> $SERVERCONF_SQL
  echo "GRANT serverconf to $DB_ADMIN_USER;" >> $SERVERCONF_SQL
  echo "GRANT TEMPORARY,CONNECT ON DATABASE serverconf TO serverconf;" >> $SERVERCONF_SQL
  echo "GRANT USAGE ON SCHEMA public to serverconf;" >> $SERVERCONF_SQL

  echo "CREATE DATABASE messagelog ENCODING 'UTF8';" > $MESSAGELOG_SQL
  echo "REVOKE ALL ON DATABASE messagelog FROM PUBLIC;" >> $MESSAGELOG_SQL
  echo "CREATE ROLE messagelog_admin LOGIN PASSWORD '$DB_MESSAGELOG_ADMIN_PASS';" >> $MESSAGELOG_SQL
  echo "GRANT messagelog_admin to $DB_ADMIN_USER;" >> $MESSAGELOG_SQL
  echo "GRANT CREATE,TEMPORARY,CONNECT ON DATABASE messagelog TO messagelog_admin;" >> $MESSAGELOG_SQL
  echo "\c messagelog" >> $MESSAGELOG_SQL
  echo "CREATE SCHEMA messagelog AUTHORIZATION messagelog_admin;" >> $MESSAGELOG_SQL
  echo "REVOKE ALL ON SCHEMA public FROM PUBLIC;" >> $MESSAGELOG_SQL
  echo "GRANT USAGE ON SCHEMA public to messagelog_admin;" >> $MESSAGELOG_SQL
  echo "CREATE ROLE messagelog LOGIN PASSWORD '$DB_MESSAGELOG_PASS';" >> $MESSAGELOG_SQL
  echo "GRANT messagelog to $DB_ADMIN_USER;" >> $MESSAGELOG_SQL
  echo "GRANT TEMPORARY,CONNECT ON DATABASE messagelog TO messagelog;" >> $MESSAGELOG_SQL
  echo "GRANT USAGE ON SCHEMA public to messagelog;" >> $MESSAGELOG_SQL

  export PGPASSWORD=$DB_ADMIN_PASS
  psql -h $DB_HOST -U $DB_ADMIN_USER -f $SERVERCONF_SQL
  psql -h $DB_HOST -U $DB_ADMIN_USER -f $MESSAGELOG_SQL
  supervisorctl stop xroad-base && supervisorctl stop xroad-confclient
  supervisorctl start postgres
  psql -h $DB_HOST -p $DB_PORT -U $DB_ADMIN_USER serverconf < $PG_DUMP
  psql -h $DB_HOST -p $DB_PORT -U $DB_ADMIN_USER messagelog < $PG_DUMP2
  supervisorctl stop postgres
  supervisorctl restart xroad-base && supervisorctl restart xroad-confclient

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf


