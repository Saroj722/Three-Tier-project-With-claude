# --- Backend Dockerfile ---
# Single-stage is fine here: we're not compiling anything, just running
# plain Node.js. Using the 'slim' variant keeps the image smaller than
# full node:20, which matters for ECR storage costs and ECS pull times.
FROM node:20-slim

# Run as a non-root user - ECS/Fargate best practice and something
# security-minded interviewers will ask about.
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app

# Copy only package files first so Docker can cache the npm install layer
# and skip re-downloading deps when only source code changes.
COPY package*.json ./
RUN npm ci --omit=dev

COPY src/ ./src/

# COPY preserves host file permissions verbatim. If the source files on
# the build host happen to have restrictive permissions (e.g. 700 on a
# directory, common after certain unzip/scp operations), the non-root
# 'appuser' below would be unable to read them even though 'root' (who
# ran the COPY) could. Explicitly normalize ownership so the image's
# behavior never depends on the build host's umask.
RUN chown -R appuser:appgroup /app

# Container-level health check. ECS can also define its own healthcheck
# in the task definition, but having one baked into the image means
# `docker run` and `docker-compose` behave the same way too.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

USER appuser

EXPOSE 4000

CMD ["node", "src/server.js"]
