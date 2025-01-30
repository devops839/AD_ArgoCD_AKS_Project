# Use the official PostgreSQL 15 Alpine image as the base
FROM postgres:15-alpine

# Set environment variables (these can also be set in Kubernetes)
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres

# Expose the default PostgreSQL port
EXPOSE 5432

# Set the default command to run PostgreSQL
CMD ["postgres"]
