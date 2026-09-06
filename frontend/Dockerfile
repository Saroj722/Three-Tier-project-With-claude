# --- Frontend Dockerfile ---
# Stage 1: build the static React bundle
FROM node:20-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY public/ ./public/
COPY src/ ./src/
RUN npm run build

# Stage 2: serve the static bundle with nginx.
# This is the image that actually ships to ECR/ECS - it contains no
# node_modules, no source code, just static files + nginx. Much smaller
# and a smaller attack surface than shipping the build stage.
FROM nginx:1.27-alpine

# nginx.conf.template gets processed by the official nginx entrypoint's
# envsubst step at container start (any file under /etc/nginx/templates/
# ending in .template is rendered to /etc/nginx/conf.d/ using env vars).
# This lets BACKEND_HOST differ between docker-compose (service name
# "backend") and any other environment without rebuilding the image.
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
ENV BACKEND_HOST=backend
ENV BACKEND_PORT=4000

COPY --from=build /app/build /usr/share/nginx/html

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
