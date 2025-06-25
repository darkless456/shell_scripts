#!/bin/bash


# echo "144.34.226.109  server.self-media.org" >> /etc/hosts
echo "2607:8700:5500:5b99::2  server.self-media.org" >> /etc/hosts

echo -n | openssl s_client -showcerts -connect server.self-media.org:443 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > self-media.org.crt

mv self-media.org.crt /usr/local/share/ca-certificates/
update-ca-certificates
tail /etc/ssl/certs/ca-certificates.crt -n 50