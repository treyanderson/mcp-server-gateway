#!/bin/bash
# Generate self-signed certificates for development/testing
# For production, use Let's Encrypt or a proper CA

set -e

CERT_DIR="${1:-./certs}"
DAYS="${2:-365}"
HOSTNAME="${3:-localhost}"

mkdir -p "$CERT_DIR"

echo "Generating self-signed certificate for: $HOSTNAME"

openssl req -x509 -newkey rsa:4096 \
  -keyout "$CERT_DIR/key.pem" \
  -out "$CERT_DIR/cert.pem" \
  -days "$DAYS" \
  -nodes \
  -subj "/CN=$HOSTNAME" \
  -addext "subjectAltName=DNS:$HOSTNAME,DNS:localhost,IP:127.0.0.1"

echo ""
echo "Certificates generated:"
echo "  Certificate: $CERT_DIR/cert.pem"
echo "  Private Key: $CERT_DIR/key.pem"
echo ""
echo "Add to config.json:"
echo '  "tls": {'
echo '    "cert": "'$CERT_DIR'/cert.pem",'
echo '    "key": "'$CERT_DIR'/key.pem"'
echo '  }'
