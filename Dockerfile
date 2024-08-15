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

RUN apt-get install -y \
build-essential curl wget sudo vim tmux unzip rsync \
net-tools iputils-ping openssh-server ufw git \
python3 python3-pip default-jdk cmake gdb \
locate man-db bash-completion apt-transport-https \
ca-certificates software-properties-common \
lsblk df du fdisk gzip

# Run the Node.js setup script with sudo
RUN bash nodesource_setup.sh

# Install Node.js
RUN apt-get install -y nodejs

RUN apt-get install -y jq

# Clean up
RUN rm nodesource_setup.sh \
    && apt-get clean

WORKDIR /home/nobody

# Create and change to the app directory
WORKDIR /usr/src/app
COPY upload.sh .
RUN cat upload.sh >> /home/nobody/.bashrc

RUN mkdir -p /home/nobody
ENV HOME=/home/nobody

# Copy application files
COPY package*.json ./
COPY index.js ./

# Install dependencies
RUN npm install

# Expose the port the app runs on
EXPOSE 3000

# Command to run the application
CMD ["node", "index.js"]
