#!/bin/bash
yum install docker -y

systemctl start docker.service
systemctl enable docker.service
usermod -a -G docker ec2-user

docker pull aariasoman/nodejs-mysql-app:latest
docker container run --name nodejs_container1 -p 8081:8080 aariasoman/nodejs-mysql-app:latest
