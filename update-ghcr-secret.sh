#!/usr/bin/env bash
set -euo pipefail

# Configuration: environment variables and file paths
RSA_KEY_PATH="${RSA_KEY_PATH:-/mnt/key/private-key.pem}"   # Path to GitHub App PEM key (mounted file)
GITHUB_APP_ID="${GITHUB_APP_ID:?}"                         # GitHub App ID (set via env)
GITHUB_INSTALLATION_ID="${GITHUB_INSTALLATION_ID:?}"       # GitHub App Installation ID (set via env)
REFRESH_INTERVAL="${REFRESH_INTERVAL:-600}"                # Token lifetime in seconds (default 600s, per GitHub max 10 min for JWT)

# Ensure the private key file is present
if [[ ! -r "$RSA_KEY_PATH" ]]; then
  echo "ERROR: RSA key file not found at $RSA_KEY_PATH" >&2
  exit 1
fi

# Construct JWT (JSON Web Token) for GitHub App authentication
iat=$(date +%s)                                     # Issued-at time (seconds since epoch)
exp=$(( iat + REFRESH_INTERVAL ))                  # Expiration time for JWT (iat + 600s by default)
header='{"alg":"RS256","typ":"JWT"}'
payload="{\"iat\":$iat,\"exp\":$exp,\"iss\":${GITHUB_APP_ID}}"
# Base64-url encode function (remove padding, replace '+' '/' as required by JWT spec)
b64() { openssl base64 -e -A | tr '+/' '-_' | tr -d '='; }
# Encode header and payload, then sign with the RSA private key to get the JWT
jwt=$(echo -n "$header" | b64).$(echo -n "$payload" | b64)
sig=$(echo -n "$jwt" | openssl dgst -sha256 -sign "$RSA_KEY_PATH" | b64)
jwt="${jwt}.${sig}"

# Exchange the JWT for an installation access token from GitHub API
token=$(curl -fsSL -H "Authorization: Bearer $jwt" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/${GITHUB_INSTALLATION_ID}/access_tokens" | jq -r .token)
# (The token is short-lived, expiring in ~1 hour:contentReference[oaicite:9]{index=9}, and grants the App's installation permissions.)

# Create Docker config JSON with the token for GHCR auth
# (GitHub Container Registry accepts the installation token as a password; username can be anything, e.g. "unused")
auth=$(echo -n "unused:${token}" | base64 -w0)
echo "{\"auths\":{\"ghcr.io\":{\"auth\":\"${auth}\"}}}" > /tmp/dockerconfigjson

# Create or update the Kubernetes Secret in the same namespace
# This uses kubectl (which assumes in-cluster config via ServiceAccount) to apply the secret manifest.
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io --docker-config-json=/tmp/dockerconfigjson \
  --dry-run=client -o yaml | kubectl apply -f -
