

FROM node:18-alpine AS builder

WORKDIR /app

COPY ./app/package.json ./

RUN npm install

COPY ./app ./

FROM node:18-alpine

WORKDIR /app

COPY --from=builder /app ./

EXPOSE 3000

CMD ["node", "server.js"]

