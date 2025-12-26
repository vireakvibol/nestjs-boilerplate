# Base stage
FROM node:22-alpine AS base
COPY . /app
WORKDIR /app

# Install production dependencies
FROM base AS prod-deps
ENV NODE_ENV=production
RUN --mount=type=cache,id=npm,target=/root/.npm npm ci --omit=dev

# Build stage
FROM base AS build
RUN --mount=type=cache,id=npm,target=/root/.npm npm install
RUN npx prisma generate
RUN npm run build

# Final runtime stage using Bun
FROM oven/bun:1.3-alpine AS runtime
ENV NODE_ENV=production
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
WORKDIR /app

# Copy built app and dependencies
COPY --from=prod-deps --chown=nodejs:nodejs /app/node_modules /app/node_modules
COPY --from=build --chown=nodejs:nodejs /app/dist /app/dist

# Optional: create non-root user (Bun image already runs as bun user)
# USER bun
USER nodejs
EXPOSE 3000

# Run with Bun
CMD ["bun", "dist/src/main.js"]