# Use Ubuntu 24.04 LTS as base image
FROM ubuntu:24.04

# Prevent tzdata from prompting during build
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y \
        curl \
        build-essential \
        python-is-python3 \
        python3 \
        libcairo2-dev \
        libjpeg-dev \
        libgif-dev \
    && curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh
    
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential curl wget vim tmux \
    unzip rsync net-tools iputils-ping nano \
    git python3 python3-pip default-jdk cmake \
    gdb locate man-db bash-completion apt-transport-https \
    ca-certificates software-properties-common util-linux gzip \
    traceroute dnsutils tcpdump nmap htop \
    lsof psmisc \
    parted e2fsprogs btrfs-progs xfsprogs \
    sed gawk grep diffutils bzip2 \
    xz-utils busybox netcat-traditional less \
    pcp- pcp-conf- libpfm4- libpcp3t64- libpcp-archive1t64- \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
# Run the Node.js setup script with sudo
RUN bash nodesource_setup.sh

# Install Node.js
RUN apt-get install -y nodejs

RUN apt-get install -y jq

RUN echo "* hard nproc 100" >> /etc/security/limits.conf && \
    echo "* soft nproc 50" >> /etc/security/limits.conf && \
    echo "* hard nofile 1024" >> /etc/security/limits.conf && \
    echo "* soft nofile 512" >> /etc/security/limits.conf && \
    echo "* hard as 512000" >> /etc/security/limits.conf && \
    echo "* soft as 256000" >> /etc/security/limits.conf && \
    echo "root hard nproc unlimited" >> /etc/security/limits.conf

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
COPY INFO.txt ./

# Install dependencies
RUN npm install

# Expose the port the app runs on
EXPOSE 3000

# Command to run the application
CMD ["node", "index.js"]
