FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
        ca-certificates gnupg supervisor net-tools iproute2 locales \
        openjdk-11-jre-headless rlwrap ca-certificates-java \
        crudini adduser expect curl rsyslog \
    && echo "LC_ALL=en_US.UTF-8" >>/etc/environment \
    && locale-gen en_US.UTF-8 \
    && adduser --quiet --system --uid 998 --home /var/lib/postgresql --no-create-home --shell /bin/bash --group postgres \
    && adduser --quiet --system --uid 999 --home /var/lib/xroad --no-create-home --shell /bin/bash --group xroad \
    && useradd -m xrd -s /usr/sbin/nologin -p '$6$JeOzaeWnLAQSUVuO$GOJ0wUKSVQnOR4I2JgZxdKr.kMO.YGS21SGaAshaYhayv8kSV9WuIFCZHTGAX8WRRTB/2ojuLnJg4kMoyzpcu1' \
    && echo "xroad-proxy xroad-common/username string xrd" | debconf-set-selections \
    && apt-get -qq install postgresql postgresql-contrib \
    && apt-get -qq clean

ARG DIST=jammy-current
ARG REPO=https://artifactory.niis.org/xroad-release-deb
ARG REPO_KEY=https://artifactory.niis.org/api/gpg/key/public
ARG COMPONENT=main

ADD ["$REPO_KEY","/tmp/repokey.gpg"]
ADD ["${REPO}/dists/${DIST}/Release","/tmp/Release"]
RUN echo "deb $REPO $DIST $COMPONENT" >/etc/apt/sources.list.d/xroad.list \
    && apt-key add '/tmp/repokey.gpg'

RUN pg_ctlcluster 14 main start \
    && apt-get update \
    && apt-get -qq install xroad-securityserver xroad-autologin xroad-database-remote \
    && apt-get -qq clean \
    && pg_ctlcluster 14 main stop

# back up read-only config (for volume support)
RUN mkdir -p /root/etc/xroad \
    && cp -a /etc/xroad /root/etc/ \
    && rm -f /root/etc/xroad/services/local.properties \
      /root/etc/xroad/conf.d/local.ini \
      /root/etc/xroad/devices.ini \
      /root/etc/xroad/db.properties \
    && rm -rf /root/etc/xroad/signer/softtoken \
    && dpkg-query --showformat='${Version}' --show xroad-proxy >/root/VERSION \
    && cp /root/VERSION /etc/xroad/VERSION

ARG XROAD_PROPERTIES="/etc/xroad.properties"
ARG DB_PROPERTIES="/etc/xroad/db.properties"
ARG SERVERCONF_SQL="/etc/xroad/db_serverconf.sql"
ARG MESSAGELOG_SQL="/etc/xroad/db_messagelog.sql"
ARG OPMON_SQL="/etc/xroad/db_opmon.sql"

RUN touch $XROAD_PROPERTIES && chown root:root $XROAD_PROPERTIES && chmod 600 $XROAD_PROPERTIES
  
RUN chown xroad:xroad /etc/xroad && chmod 751 /etc/xroad && touch $DB_PROPERTIES && chmod 0640 $DB_PROPERTIES && chown xroad:xroad $DB_PROPERTIES  

RUN touch $SERVERCONF_SQL && chmod 0640 $SERVERCONF_SQL && chown xroad:xroad $SERVERCONF_SQL 

RUN touch $MESSAGELOG_SQL && chmod 0640 $MESSAGELOG_SQL && chown xroad:xroad $MESSAGELOG_SQL 

RUN touch $OPMON_SQL && chmod 0640 $OPMON_SQL && chown xroad:xroad $OPMON_SQL

ARG REMOTE_DB_HOST
ENV REMOTE_DB_HOST=${REMOTE_DB_HOST}
ARG REMOTE_DB_PORT
ENV REMOTE_DB_PORT=${REMOTE_DB_PORT}
ARG REMOTE_DB_USER
ENV REMOTE_DB_USER=${REMOTE_DB_USER}
ARG REMOTE_DB_PASS
ENV REMOTE_DB_PASS=${REMOTE_DB_PASS}
ARG SERVERCONF_ADMIN_PASS
ENV SERVERCONF_ADMIN_PASS=${SERVERCONF_ADMIN_PASS}
ARG OPMONITOR_ADMIN_PASS
ENV OPMONITOR_ADMIN_PASS=${OPMONITOR_ADMIN_PASS}
ARG MESSAGELOG_ADMIN_PASS
ENV MESSAGELOG_ADMIN_PASS=${MESSAGELOG_ADMIN_PASS}
ARG SERVERCONF_PASS
ENV SERVERCONF_PASS=${SERVERCONF_PASS}
ARG OPMONITOR_PASS
ENV OPMONITOR_PASS=${OPMONITOR_PASS}
ARG MESSAGELOG_PASS
ENV MESSAGELOG_PASS=${MESSAGELOG_PASS}

RUN echo "postgres.connection.password = $REMOTE_DB_PASS" > $XROAD_PROPERTIES \
  && echo "postgres.connection.user = $REMOTE_DB_USER " >> $XROAD_PROPERTIES \
  && echo "serverconf.database.admin_user = serverconf_admin" >> $XROAD_PROPERTIES \
  && echo "serverconf.database.admin_password = $SERVERCONF_ADMIN_PASS" >> $XROAD_PROPERTIES \
  && echo "op-monitor.database.admin_user = opmonitor_admin" >> $XROAD_PROPERTIES \
  && echo "op-monitor.database.admin_password = $OPMONITOR_ADMIN_PASS" >> $XROAD_PROPERTIES \
  && echo "messagelog.database.admin_user = messagelog_admin" >> $XROAD_PROPERTIES \
  && echo "messagelog.database.admin_password = $MESSAGELOG_ADMIN_PASS" >> $XROAD_PROPERTIES

RUN echo "serverconf.hibernate.connection.url = jdbc:postgresql://$REMOTE_DB_HOST:$REMOTE_DB_PORT/serverconf" > $DB_PROPERTIES \
  && echo "serverconf.hibernate.connection.username = serverconf" >> $DB_PROPERTIES \
  && echo "serverconf.hibernate.connection.password = $SERVERCONF_PASS" >> $DB_PROPERTIES \ 
  && echo "serverconf.hibernate.hikari.dataSource.currentSchema = serverconf,public" >> $DB_PROPERTIES \
  && echo "messagelog.hibernate.connection.url = jdbc:postgresql://$REMOTE_DB_HOST:$REMOTE_DB_PORT/messagelog" >> $DB_PROPERTIES \
  && echo "messagelog.hibernate.connection.username = messagelog" >> $DB_PROPERTIES \
  && echo "messagelog.hibernate.connection.password = $MESSAGELOG_PASS" >> $DB_PROPERTIES \
  && echo "messagelog.hibernate.hikari.dataSource.currentSchema = messagelog,public" >> $DB_PROPERTIES \
  && echo "op-monitor.hibernate.connection.url = jdbc:postgresql://<$REMOTE_DB_HOST:$REMOTE_DB_PORT/op-monitor" >> $DB_PROPERTIES \
  && echo "op-monitor.hibernate.connection.username = opmonitor" >> $DB_PROPERTIES \
  && echo "op-monitor.hibernate.connection.password = $OPMONITOR_PASS" >> $DB_PROPERTIES \
  && echo "op-monitor.hibernate.hikari.dataSource.currentSchema = opmonitor,public" >> $DB_PROPERTIES


RUN echo "CREATE DATABASE serverconf ENCODING 'UTF8';" > $SERVERCONF_SQL \
  && echo "REVOKE ALL ON DATABASE serverconf FROM PUBLIC;" >> $SERVERCONF_SQL \
  && echo "CREATE ROLE serverconf_admin LOGIN PASSWORD '$SERVERCONF_ADMIN_PASS';" >> $SERVERCONF_SQL \
  && echo "GRANT serverconf_admin to $REMOTE_DB_USER;" >> $SERVERCONF_SQL \
  && echo "GRANT CREATE,TEMPORARY,CONNECT ON DATABASE serverconf TO serverconf_admin;" >> $SERVERCONF_SQL \
  && echo "\c serverconf" >> $SERVERCONF_SQL \
  && echo "CREATE EXTENSION hstore;" >> $SERVERCONF_SQL \
  && echo "CREATE SCHEMA serverconf AUTHORIZATION serverconf_admin;" >> $SERVERCONF_SQL \
  && echo "REVOKE ALL ON SCHEMA public FROM PUBLIC;" >> $SERVERCONF_SQL \
  && echo "GRANT USAGE ON SCHEMA public to serverconf_admin;" >> $SERVERCONF_SQL \
  && echo "CREATE ROLE serverconf LOGIN PASSWORD '$SERVERCONF_PASS';" >> $SERVERCONF_SQL \
  && echo "GRANT serverconf to $REMOTE_DB_USER;" >> $SERVERCONF_SQL \
  && echo "GRANT TEMPORARY,CONNECT ON DATABASE serverconf TO serverconf;" >> $SERVERCONF_SQL \
  && echo "GRANT USAGE ON SCHEMA public to serverconf;" >> $SERVERCONF_SQL

RUN echo "CREATE DATABASE messagelog ENCODING 'UTF8';" > $MESSAGELOG_SQL \
  && echo "REVOKE ALL ON DATABASE messagelog FROM PUBLIC;" >> $MESSAGELOG_SQL \
  && echo "CREATE ROLE messagelog_admin LOGIN PASSWORD '$MESSAGELOG_ADMIN_PASS';" >> $MESSAGELOG_SQL \
  && echo "GRANT messagelog_admin to $REMOTE_DB_USER;" >> $MESSAGELOG_SQL\
  && echo "GRANT CREATE,TEMPORARY,CONNECT ON DATABASE messagelog TO messagelog_admin;" >> $MESSAGELOG_SQL \
  && echo "\c messagelog" >> $MESSAGELOG_SQL \
  && echo "CREATE SCHEMA messagelog AUTHORIZATION messagelog_admin;" >> $MESSAGELOG_SQL \
  && echo "REVOKE ALL ON SCHEMA public FROM PUBLIC;" >> $MESSAGELOG_SQL \
  && echo "GRANT USAGE ON SCHEMA public to messagelog_admin;" >> $MESSAGELOG_SQL \
  && echo "CREATE ROLE messagelog LOGIN PASSWORD '$MESSAGELOG_PASS';" >> $MESSAGELOG_SQL \
  && echo "GRANT messagelog to $REMOTE_DB_USER;" >> $MESSAGELOG_SQL \
  && echo "GRANT TEMPORARY,CONNECT ON DATABASE messagelog TO messagelog;" >> $MESSAGELOG_SQL \
  && echo "GRANT USAGE ON SCHEMA public to messagelog;" >> $MESSAGELOG_SQL

RUN echo "CREATE DATABASE \"op-monitor\" ENCODING 'UTF8';" > $OPMON_SQL \
  && echo "REVOKE ALL ON DATABASE \"op-monitor\" FROM PUBLIC;" >> $OPMON_SQL \
  && echo "CREATE ROLE opmonitor_admin LOGIN PASSWORD '$OPMONITOR_ADMIN_PASS';" >> $OPMON_SQL \
  && echo "GRANT opmonitor_admin to $REMOTE_DB_USER;" >> $OPMON_SQL \
  && echo "GRANT CREATE,TEMPORARY,CONNECT ON DATABASE \"op-monitor\" TO opmonitor_admin;" >> $OPMON_SQL \
  && echo "\c \"op-monitor\"" >> $OPMON_SQL \
  && echo "CREATE SCHEMA opmonitor AUTHORIZATION opmonitor_admin;" >> $OPMON_SQL \
  && echo "REVOKE ALL ON SCHEMA public FROM PUBLIC;" >> $OPMON_SQL \
  && echo "GRANT USAGE ON SCHEMA public to opmonitor_admin;" >> $OPMON_SQL \
  && echo "CREATE ROLE opmonitor LOGIN PASSWORD '$OPMONITOR_PASS';" >> $OPMON_SQL \
  && echo "GRANT opmonitor to $REMOTE_DB_USER;" >> $OPMON_SQL \
  && echo "GRANT TEMPORARY,CONNECT ON DATABASE \"op-monitor\" TO opmonitor;" >> $OPMON_SQL \
  && echo "GRANT USAGE ON SCHEMA public to opmonitor;" >> $OPMON_SQL

ENV PGPASSWORD=${REMOTE_DB_PASS}
RUN psql -h $REMOTE_DB_HOST -U $REMOTE_DB_USER -f $SERVERCONF_SQL
RUN psql -h $REMOTE_DB_HOST -U $REMOTE_DB_USER -f $MESSAGELOG_SQL
RUN psql -h $REMOTE_DB_HOST -U $REMOTE_DB_USER -f $OPMON_SQL

COPY files/ss-entrypoint.sh /root/entrypoint.sh
COPY --chown=xroad:xroad files/override-docker.ini /etc/xroad/conf.d/
COPY --chown=root:root files/ss-xroad.conf /etc/supervisor/conf.d/xroad.conf
CMD ["/root/entrypoint.sh"]

EXPOSE 8080 8443 4000 5500 5577
