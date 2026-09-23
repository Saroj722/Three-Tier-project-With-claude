# Pulled from Amazon ECR Public (a mirror of the official Docker Hub image)
# rather than docker.io directly. CodeBuild's shared build fleet IPs
# frequently hit Docker Hub's anonymous-pull rate limit (429 Too Many
# Requests) - ECR Public sidesteps that for AWS-originating traffic.
FROM public.ecr.aws/docker/library/node:20-slim

RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY src/ ./src/

RUN chown -R appuser:appgroup /app

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

USER appuser

EXPOSE 4000

CMD ["node", "src/server.js"]
