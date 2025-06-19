#!/usr/bin/env bash
set -euo pipefail

# Expect RSA private key at a mounted path
RSA_KEY_PATH="${RSA_KEY_PATH:-/mnt/key/private-key.pem}"
if [[ ! -r "$RSA_KEY_PATH" ]]; then
  echo "ERROR: RSA key file not found at $RSA_KEY_PATH" >&2
  exit 1
fi

# JWT header
header='{"alg":"RS256","typ":"JWT"}'
# JWT payload
iat=$(date +%s)
exp=$(( iat + (REFRESH_INTERVAL:–600) ))
payload=$(cat <<EOF
{"iat":$iat,"exp":$exp,"iss":${GITHUB_APP_ID}}
EOF
)

# Base64url encoding
b64() { openssl base64 -e -A | tr '+/' '-_' | tr -d '='; }

jwt="${header}" | b64
jwt+="."$(echo "$payload" | b64)
sig=$(echo -n "${jwt}" | openssl dgst -sha256 -sign "$RSA_KEY_PATH" | b64)
jwt="${jwt}.${sig}"

# Exchange for installation token
token=$(curl -sSL \
  -H "Authorization: Bearer $jwt" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/${GITHUB_INSTALLATION_ID}/access_tokens" \
  | jq -r .token)

# Build Docker credentials JSON
auth=$(echo -n "unused:${token}" | base64 -w 0)
echo "{\"auths\":{\"ghcr.io\":{\"auth\":\"${auth}\"}}}" > /tmp/dockerconfigjson

# Apply Kubernetes secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-config-json=/tmp/dockerconfigjson \
  --dry-run=client -o yaml \
  | kubectl apply -f -
