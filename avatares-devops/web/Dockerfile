FROM node:18-alpine

EXPOSE 5173

WORKDIR /web

COPY package.json /web

RUN npm install

COPY . /web

CMD ["npm", "run", "dev"]
