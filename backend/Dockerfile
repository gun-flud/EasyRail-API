FROM node:22-alpine

WORKDIR /app

RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN pnpm install

COPY . .
RUN pnpm build

RUN chown -R node:node /app
USER node

EXPOSE 8080

CMD ["node", "dist/server.js"]