FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and kubectl
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl ca-certificates gnupg bash jq openssl && \
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key \
      | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" \
      > /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends kubectl && \
    rm -rf /var/lib/apt/lists/*

# Copy the update script into the image
COPY update-ghcr-secret.sh /usr/local/bin/update-ghcr-secret.sh

# Run the script on container start
ENTRYPOINT ["/usr/local/bin/update-ghcr-secret.sh"]
