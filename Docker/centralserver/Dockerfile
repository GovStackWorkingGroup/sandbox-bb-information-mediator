FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update \
  && apt-get -qq upgrade \
  && apt-get -qq install sudo ca-certificates gnupg supervisor net-tools locales openjdk-8-jre-headless rlwrap ca-certificates-java crudini adduser expect nginx-light curl rsyslog wget python3 \
  && echo "LC_ALL=en_US.UTF-8" >>/etc/environment \
  && locale-gen en_US.UTF-8 \
  && adduser --quiet --system --uid 998 --home /var/lib/postgresql --no-create-home --shell /bin/bash --group postgres \
  && adduser --quiet --system --uid 999 --home /var/lib/xroad --no-create-home --shell /bin/bash --group xroad \
  && useradd -m xrd -s /usr/sbin/nologin -p '$6$JeOzaeWnLAQSUVuO$GOJ0wUKSVQnOR4I2JgZxdKr.kMO.YGS21SGaAshaYhayv8kSV9WuIFCZHTGAX8WRRTB/2ojuLnJg4kMoyzpcu1' \
  && echo "xroad-center xroad-common/username string xrd" | debconf-set-selections \
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
  && apt-get -qq update \
  && apt-get -qq install xroad-centralserver xroad-autologin xroad-database-remote \
  && apt-get -qq clean \
  && pg_ctlcluster 14 main stop \
  && { nginx -s stop ||:; } \
  && rm -f /var/run/nginx.pid \
  && rm -rf /tmp/xroad

# back up read-only config (for volume support)
RUN mkdir -p /root/etc/xroad \
  && cp -a /etc/xroad /root/etc/ \
  && rm -f /root/etc/xroad/services/local.properties \
     /root/etc/xroad/conf.d/local.ini \
     /root/etc/xroad/devices.ini \
     /root/etc/xroad/db.properties \
  && dpkg-query --showformat='${Version}' --show xroad-center >/root/VERSION \
  && cp /root/VERSION /etc/xroad/VERSION
  

ARG XROAD_PROPERTIES="/etc/xroad.properties"
ARG DB_PROPERTIES="/etc/xroad/db.properties"  
ARG CENTERUI_SQL="/etc/xroad/centerui.sql"
  
RUN touch $XROAD_PROPERTIES && chown root:root $XROAD_PROPERTIES && chmod 600 $XROAD_PROPERTIES
RUN chown xroad:xroad /etc/xroad && chmod 751 /etc/xroad && touch $DB_PROPERTIES && chmod 0640 $DB_PROPERTIES && chown xroad:xroad $DB_PROPERTIES  
RUN touch $CENTERUI_SQL && chmod 0640 $CENTERUI_SQL && chown xroad:xroad $CENTERUI_SQL 

ARG REMOTE_DB_HOST
ENV REMOTE_DB_HOST=${REMOTE_DB_HOST}
ARG REMOTE_DB_PORT
ENV REMOTE_DB_PORT=${REMOTE_DB_PORT}
ARG REMOTE_DB_USER
ENV REMOTE_DB_USER=${REMOTE_DB_USER}
ARG REMOTE_DB_PASS
ENV REMOTE_DB_PASS=${REMOTE_DB_PASS}
ARG CENTRAL_SERVER_DB_PASS
ENV CENTRAL_SERVER_DB_PASS=${CENTRAL_SERVER_DB_PASS}

RUN echo "postgres.connection.password = $REMOTE_DB_PASS" > $XROAD_PROPERTIES \
  && echo "postgres.connection.user = $REMOTE_DB_USER " >> $XROAD_PROPERTIES

RUN echo "adapter=postgresql" > $DB_PROPERTIES \
  && echo "encoding=utf8" >> $DB_PROPERTIES \
  && echo "username=centerui" >> $DB_PROPERTIES \
  && echo "password=$CENTRAL_SERVER_DB_PASS" >> $DB_PROPERTIES \
  && echo "database=centerui_production" >> $DB_PROPERTIES \
  && echo "schema=centerui" >> $DB_PROPERTIES \
  && echo "reconnect=true" >> $DB_PROPERTIES \
  && echo "host=$REMOTE_DB_HOST" >> $DB_PROPERTIES \
  && echo "port=$REMOTE_DB_PORT" >> $DB_PROPERTIES \
  && echo "skip_migrations=false" >> $DB_PROPERTIES
  
RUN echo "CREATE DATABASE centerui_production ENCODING 'UTF8';" > $CENTERUI_SQL \
  && echo "REVOKE ALL ON DATABASE centerui_production FROM PUBLIC;" >> $CENTERUI_SQL \
  && echo "CREATE ROLE centerui LOGIN PASSWORD '$CENTRAL_SERVER_DB_PASS';" >> $CENTERUI_SQL \
  && echo "GRANT centerui to $REMOTE_DB_USER;" >> $CENTERUI_SQL \
  && echo "GRANT CREATE,TEMPORARY,CONNECT ON DATABASE centerui_production TO centerui;" >> $CENTERUI_SQL \
  && echo "\c centerui_production" >> $CENTERUI_SQL \
  && echo "CREATE EXTENSION hstore;" >> $CENTERUI_SQL \
  && echo "CREATE SCHEMA centerui AUTHORIZATION centerui;" >> $CENTERUI_SQL \
  && echo "REVOKE ALL ON SCHEMA public FROM PUBLIC;" >> $CENTERUI_SQL \
  && echo "GRANT USAGE ON SCHEMA public to centerui;  " >> $CENTERUI_SQL

ENV PGPASSWORD=${REMOTE_DB_PASS}
RUN psql -h $REMOTE_DB_HOST -U $REMOTE_DB_USER -f $CENTERUI_SQL

#Setup TEST-CA with TSA and OCSP
RUN useradd -m ca -U \
  && useradd -G ca ocsp
COPY build/home /home
COPY build/etc /etc
COPY files/init.sh /home/ca/CA/
COPY files/ca.py /home/ca/CA/
RUN chown -R ca:ca /home/ca/CA \
  && find /home/ca/TSA -type f -exec chmod 0664 {} + \
  && find /home/ca/CA -type f -exec chmod 0740 {} + \
  && chmod 0700 /home/ca/CA/init.sh \
  && mkdir -p /var/log/ \
  && touch /var/log/ocsp.log \
  && chown ca:ca /var/log/ocsp.log \
  && chmod 0664 /var/log/ocsp.log \
  && chmod 0754 /home/ca/CA/ca.py \
  && chmod 0754 /home/ca/CA/sign_req.sh

COPY files/cs-entrypoint.sh /root/entrypoint.sh
COPY --chown=root:root files/cs-xroad.conf /etc/supervisor/conf.d/xroad.conf
CMD ["/root/entrypoint.sh"]

EXPOSE 80 4000
