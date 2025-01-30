# Use Alpine Linux as the base image
FROM alpine:latest

# Install Redis
RUN apk add --no-cache redis

# Create the required data directory
RUN mkdir -p /data && chown -R redis:redis /data

# Set the default user to redis
USER redis

# Expose the Redis default port
EXPOSE 6379

# Start Redis server
CMD ["redis-server", "--appendonly", "yes"]
