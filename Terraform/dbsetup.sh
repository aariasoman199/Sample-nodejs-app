#!/bin/bash
yum install docker -y

systemctl start docker.service
systemctl enable docker.service
usermod -a -G docker ec2-user

docker pull aariasoman/mysql-college:latest
docker volume create nodejs-mysqlvol
docker container run -d --name mysql_container -v nodejs-mysqlvol:/var/lib/mysql/ --network host aariasoman/mysql-college:latest
