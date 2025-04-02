#!/bin/bash
# This script generates a self-signed wildcard certificate for a given domain

set -e  # Exit immediately if a command exits with non-zero status

DOMAIN=$1
# Check if the domain argument is provided
if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

# Check if the domain is valid
if ! [[ $DOMAIN =~ ^[a-zA-Z0-9.-]+$ ]]; then
  echo "Invalid domain name: $DOMAIN"
  exit 1
fi

# Create ssl directory if it doesn't exist
mkdir -p ssl
cd ssl

# Generate CA key and certificate in one command
echo "Generating CA certificate..."
openssl req -new -x509 -days 3650 -nodes -out ca.crt \
  -keyout ca.key -subj "/CN=self-ca" 2>/dev/null

# Generate server key and CSR in one command
echo "Generating server certificate..."
WILDCARD="*.$DOMAIN"
openssl req -new -nodes -out server.csr \
  -keyout server.key -subj "/CN=$WILDCARD" 2>/dev/null

# Create extension file with wildcard and base domain
cat > server.ext << EOF
subjectAltName = DNS:$WILDCARD, DNS:$DOMAIN
EOF

# Sign the certificate with the extension file
openssl x509 -req -in server.csr -days 3650 \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -extfile server.ext -out server.crt 2>/dev/null

# Generate client key and CSR in one command
echo "Generating client certificate..."
openssl req -new -nodes -out client.csr \
  -keyout client.key -subj "/CN=client" 2>/dev/null

# Sign the client certificate
openssl x509 -req -in client.csr -days 3650 \
  -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt 2>/dev/null

# Set appropriate permissions
chmod 600 *.key

echo "Certificate generation complete!"
echo "Wildcard certificate for *.$DOMAIN has been created."