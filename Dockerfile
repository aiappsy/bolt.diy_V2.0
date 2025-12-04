# Stage 1: Base
FROM node:20-alpine AS base

ENV PNPM_VERSION=10.18.0
RUN npm install -g pnpm@${PNPM_VERSION}

WORKDIR /app

# Stage 2: Dependencies
FROM base AS dependencies

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Stage 3: Build
FROM base AS build

COPY --from=dependencies /app/node_modules ./node_modules
COPY . .
RUN pnpm run build

# Stage 4: Production
FROM base AS production

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile

COPY --from=build /app/build/client ./build/client
COPY --from=build /app/bindings.sh ./bindings.sh

# Optional: copy wrangler.toml or other files if needed by wrangler
COPY --from=build /app/wrangler.toml ./wrangler.toml

EXPOSE 8788

CMD ["sh", "-c", "bindings=$(./bindings.sh) && wrangler pages dev ./build/client $bindings --port 8788 --ip 0.0.0.0"]
