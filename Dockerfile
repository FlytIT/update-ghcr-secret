FROM bitnami/kubectl:latest
RUN install_packages bash curl jq openssl
COPY update-ghcr-secret.sh /usr/local/bin/update-ghcr-secret.sh
ENTRYPOINT ["/usr/local/bin/update-ghcr-secret.sh"]
