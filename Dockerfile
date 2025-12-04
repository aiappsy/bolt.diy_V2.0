# ================================
# Stage 1: Base Image
# ================================
FROM node:20-alpine AS base

ENV PNPM_VERSION=10.18.0
RUN npm install -g pnpm@${PNPM_VERSION}

WORKDIR /app

# ================================
# Stage 2: Dependencies
# ================================
FROM base AS dependencies

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# ================================
# Stage 3: Build
# ================================
FROM base AS build

COPY --from=dependencies /app/node_modules ./node_modules
COPY . .
RUN pnpm run build

# ================================
# Stage 4: Production Runtime
# ================================
FROM base AS production

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile

COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules

EXPOSE 8788

# Use Vite preview for serving (default production preview)
CMD ["pnpm", "run", "preview", "--host", "0.0.0.0", "--port", "8788"]
