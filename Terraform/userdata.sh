#!/bin/bash
yum install docker -y

systemctl start docker.service
systemctl enable docker.service
usermod -a -G docker ec2-user

docker pull aariasoman/nodejs-mysql-app:latest
docker container run --name nodejs_container1 -e DATABASE_HOST= "dbinstance.chottu.shop" -e DATABASE_PORT="3306" -e DATABASE_USER="appadmin" -e DATABASE_PASSWORD="appadmin" -e DATABASE_NAME="college"  -e DATABASE_TABLE="students"  -p 8081:8080 aariasoman/nodejs-mysql-app:latest
