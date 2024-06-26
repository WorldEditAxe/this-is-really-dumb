# Use Ubuntu 20.04 LTS as base image
FROM ubuntu:20.04

# Prevent tzdata from prompting during build
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists and install necessary tools
RUN apt-get update \
    && apt-get install -y \
        curl \
        build-essential \
        python \
        libcairo2-dev \
        libjpeg-dev \
        libgif-dev \
    && curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh

# Run the Node.js setup script with sudo
RUN bash nodesource_setup.sh

# Install Node.js
RUN apt-get install -y nodejs

# Clean up
RUN rm nodesource_setup.sh \
    && apt-get clean

# Create and change to the app directory
WORKDIR /usr/src/app

# Copy application files
COPY package*.json ./
COPY index.js ./
COPY public ./public

# Install dependencies
RUN npm install

# Expose the port the app runs on
EXPOSE 3000

# Run the application as a non-root user
USER nobody

# Command to run the application
# CMD ["node", "index.js"]
CMD ["ls", "/home"]
