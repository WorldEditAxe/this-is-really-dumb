# Use Ubuntu 20.04 LTS as base image
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update \
    && apt-get install -y nodejs npm \
    && npm install -g npm

# Create and change to the app directory
WORKDIR /usr/src/app

# Copy application files
COPY package*.json ./
COPY index.js ./
COPY public ./public

# Install dependencies
RUN npm install

# Change ownership and permissions to prevent modification
RUN chown -R nobody:nobody /usr/src/app \
    && chmod -R 555 /usr/src/app

# Expose the port the app runs on
EXPOSE 3000

# Run the application as a non-root user
USER nobody

# Command to run the application
CMD [ "node", "index.js" ]
