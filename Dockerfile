FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install kubectl + dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl ca-certificates gnupg bash jq openssl apt-transport-https && \
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
      > /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl && \
    rm -rf /var/lib/apt/lists/*

# Copy the update script into the image
COPY update-ghcr-secret.sh /usr/local/bin/update-ghcr-secret.sh

# Run the script on container start
ENTRYPOINT ["/usr/local/bin/update-ghcr-secret.sh"]
