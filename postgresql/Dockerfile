# Use Alpine as the base image
FROM alpine:latest

# Install PostgreSQL
RUN apk update && apk add --no-cache postgresql15 postgresql15-contrib

# Set environment variables for PostgreSQL
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV PGDATA=/var/lib/postgresql/data

# Create required directories
RUN mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql

# Set the default user to postgres
USER postgres

# Initialize the database
RUN initdb -D /var/lib/postgresql/data

# Expose the default PostgreSQL port
EXPOSE 5432

# Start PostgreSQL server
CMD ["postgres", "-D", "/var/lib/postgresql/data"]
