# See backend/Dockerfile for why this pulls from ECR Public instead of docker.io.
FROM public.ecr.aws/docker/library/node:20-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY public/ ./public/
COPY src/ ./src/
RUN npm run build

FROM public.ecr.aws/docker/library/nginx:1.27-alpine

COPY nginx.conf.template /etc/nginx/templates/default.conf.template
ENV BACKEND_HOST=backend
ENV BACKEND_PORT=4000

COPY --from=build /app/build /usr/share/nginx/html

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
