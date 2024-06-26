# Use the official Node.js image
FROM node:16

# Create and change to the app directory
WORKDIR /usr/src/app

# Copy application files
COPY package*.json ./
COPY index.js ./
COPY public ./public

# Install dependencies
RUN npm install

# Change ownership and permissions to prevent modification
RUN chown -R root:root /usr/src/app && \
    chmod -R 555 /usr/src/app

# Expose the port the app runs on
EXPOSE 3000

# Run the application as a non-root user
USER nobody

# Command to run the application
CMD [ "node", "index.js" ]
