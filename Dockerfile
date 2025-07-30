FROM node:20-alpine

WORKDIR /var/nodeapp

COPY ./code/ .

RUN npm install

EXPOSE 8080

CMD ["npm", "start"]
