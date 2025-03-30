#!/bin/sh

mkdir -p ssl

INPUT_DOMAIN=$1
OUTPUT_FILENAME=$INPUT_DOMAIN

printf "[req]
prompt                  = no
default_bits            = 4096
default_md              = sha256
encrypt_key             = no
string_mask             = utf8only

distinguished_name      = cert_distinguished_name
req_extensions          = req_x509v3_extensions
x509_extensions         = req_x509v3_extensions

[ cert_distinguished_name ]
C  = CN
ST = BJ
L  = BJ 
O  = $INPUT_DOMAIN
OU = $INPUT_DOMAIN
CN = $INPUT_DOMAIN

[req_x509v3_extensions]
basicConstraints        = critical,CA:true
subjectKeyIdentifier    = hash
keyUsage                = critical,digitalSignature,keyCertSign,cRLSign #,keyEncipherment
extendedKeyUsage        = critical,serverAuth #, clientAuth
subjectAltName          = @alt_names

[alt_names]
DNS.1 = $INPUT_DOMAIN
DNS.2 = *.$INPUT_DOMAIN

" >ssl/${OUTPUT_FILENAME}.conf

openssl req -x509 -newkey rsa:2048 -keyout ssl/$OUTPUT_FILENAME.key -out ssl/$OUTPUT_FILENAME.crt -days 3650 -nodes -config ssl/${OUTPUT_FILENAME}.conf
