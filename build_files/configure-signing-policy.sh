#!/bin/bash
set -ouex pipefail

echo "Configuring cosign signature verification policy for ghcr.io/butterflysky..."

# Install the cosign public key
mkdir -p /etc/pki/containers
install -m 0644 /ctx/cosign.pub /etc/pki/containers/butterflysky.pub

# Add sigstoreSigned policy for ghcr.io/butterflysky to policy.json
jq '.transports.docker |= (
  . // {} | .["ghcr.io/butterflysky"] = [{
    "type": "sigstoreSigned",
    "keyPath": "/etc/pki/containers/butterflysky.pub",
    "signedIdentity": {"type": "matchRepository"}
  }]
)' /etc/containers/policy.json >/tmp/policy.json
mv /tmp/policy.json /etc/containers/policy.json

# Create registries.d config for sigstore attachment discovery
mkdir -p /etc/containers/registries.d
cat >/etc/containers/registries.d/butterflysky.yaml <<'EOF'
docker:
  ghcr.io/butterflysky:
    use-sigstore-attachments: true
EOF
