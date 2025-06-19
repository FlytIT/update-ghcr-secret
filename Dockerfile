FROM bitnami/kubectl:latest

# Install needed packages: bash (for shell), curl (for API calls), jq (JSON parsing), openssl (for JWT signing)
RUN install_packages bash curl jq openssl

# Copy the update script into the image
COPY update-ghcr-secret.sh /usr/local/bin/update-ghcr-secret.sh

# Run the script on container start
ENTRYPOINT ["/usr/local/bin/update-ghcr-secret.sh"]
