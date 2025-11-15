# Dockerfile - simple Node.js app container
FROM node:18-alpine

WORKDIR /usr/src/app

# Copy only package files first for better layer caching
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production

# Copy app sources
COPY . .

# Create non-root user and switch (security)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

ENV PORT=3000
EXPOSE 3000

CMD ["node", "app.js"]
