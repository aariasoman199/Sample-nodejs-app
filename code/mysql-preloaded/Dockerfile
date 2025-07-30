FROM mysql:latest
ARG ROOT_PASS
ENV MYSQL_ROOT_PASSWORD=$ROOT_PASS
COPY init.sql /docker-entrypoint-initdb.d/
