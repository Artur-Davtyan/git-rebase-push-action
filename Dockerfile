FROM alpine:3.18

# Install required packages
RUN apk add --no-cache \
    git \
    bash \
    curl \
    wget \
    jq \
    ca-certificates

# Install yq (latest version)
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

# Verify yq installation
RUN yq --version

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Make the script executable
RUN chmod +x /entrypoint.sh

# Set git to trust any directory (for GitHub Actions)
RUN git config --global --add safe.directory '*'

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]