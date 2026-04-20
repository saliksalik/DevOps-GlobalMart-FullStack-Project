# ──────────────────────────────────────────────────────────
# Stage 1: Builder — install ALL deps (including devDeps)
# ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

LABEL maintainer="globalmart-devops@company.com"
LABEL stage="builder"

WORKDIR /app

# Copy manifests first to leverage Docker layer cache
COPY package*.json ./

# Install ALL dependencies (needed for tests/build)
RUN npm ci

# Copy source code
COPY . .

# Run tests during build to catch failures early (CI Gate)
RUN npm test

# ──────────────────────────────────────────────────────────
# Stage 2: Production — lean image, no devDeps, no test code
# ──────────────────────────────────────────────────────────
FROM node:20-alpine AS production

LABEL maintainer="globalmart-devops@company.com"
LABEL stage="production"

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy manifests and install ONLY production deps
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy only the application source (not tests, not node_modules from builder)
COPY --from=builder /app/src ./src

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app
USER appuser

# Expose the application port
EXPOSE 3000

# Health check (Docker-native)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', r => r.statusCode === 200 ? process.exit(0) : process.exit(1)).on('error', () => process.exit(1))"

# Start the server
CMD ["node", "src/server.js"]
