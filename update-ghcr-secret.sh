#!/bin/bash
set -euo pipefail

now=$(date +%s)
exp=$((now + REFRESH_INTERVAL))

header='{"alg":"RS256","typ":"JWT"}'
payload=$(jq -n --arg i "$GITHUB_APP_ID" --argjson now "$now" --argjson exp "$exp" \
  '{iss: ($i | tonumber), iat: $now, exp: $exp}')

b64enc() { openssl base64 -e -A | tr '+/' '-_' | tr -d '='; }
sign() {
  openssl dgst -sha256 -sign <(echo "$GITHUB_PRIVATE_KEY") | b64enc
}

header_b64=$(echo -n "$header" | b64enc)
payload_b64=$(echo -n "$payload" | b64enc)
signature=$(echo -n "$header_b64.$payload_b64" | sign)
jwt="$header_b64.$payload_b64.$signature"

access_token=$(curl -s -X POST \
  -H "Authorization: Bearer $jwt" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$GITHUB_INSTALLATION_ID/access_tokens" \
  | jq -r .token)

AUTH=$(echo -n "USERNAME:$access_token" | base64)
docker_config=$(jq -n \
  --arg auth "$AUTH" \
  '{
    "auths": {
      "ghcr.io": {
        "auth": $auth
      }
    }
  }')

kubectl create secret generic ghcr-secret \
  --type=kubernetes.io/dockerconfigjson \
  --from-literal=.dockerconfigjson="$(echo $docker_config)" \
  --dry-run=client -o yaml | kubectl apply -f -
