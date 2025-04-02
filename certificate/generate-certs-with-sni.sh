#!/bin/bash
# This script generates a self-signed wildcard certificate for a given domain

set -e

SNI=$1
# Check if the sni argument is provided
if [ -z "$SNI" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi
# Check if the sni is valid
if ! [[ $SNI =~ ^[a-zA-Z0-9.-]+$ ]]; then
  echo "Invalid sni name: $SNI"
  exit 1
fi

mkdir -p ssl
cd ssl

# Generate CA
openssl req -new -x509 -days 3650 -nodes -text -out ca.crt \
  -keyout ca.key -subj "/CN=self-ca"

# Generate server certificate for Traefik
openssl req -new -nodes -text -out server.csr \
  -keyout server.key -subj "/CN=$SNI"

# Add Subject Alternative Name (SAN)
cat > server.ext << EOF
subjectAltName = DNS:$SNI
EOF

# Sign the certificate
openssl x509 -req -in server.csr -days 3650 \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -extfile server.ext -out server.crt

# Generate client certificate for client
openssl req -new -nodes -text -out client.csr \
  -keyout client.key -subj "/CN=client"

# Sign the client certificate
openssl x509 -req -in client.csr -days 3650 \
  -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt

chmod 600 server.key client.key

echo "Certificate generation complete!"
echo "Certificate for $SNI has been created."