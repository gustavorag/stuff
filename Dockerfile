
ARG container_name=mariadb
ARG version=latest
ARG root_password='temp123'
ARG zix_user_password='temp123'

FROM ${container_name}:${version} as vendor-usage-database

ENV MYSQL_ROOT_PASSWORD='temp123'
ENV ZIX_USER_PASSWORD='temp123'

EXPOSE 3306
EXPOSE 33060
#
# RUN /etc/init.d/mysql start
# RUN mysql -u root -p${MYSQL_ROOT_PASSWORD} -h 127.0.0.1 -P 3306 -e "CREATE USER 'zix-user'@'%' IDENTIFIED BY 'test';"

RUN mkdir /tempFolder
COPY zix_usage_db.sql /tempFolder.
COPY init.sh /docker-entrypoint-initdb.d/
