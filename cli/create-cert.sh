#!/bin/bash
set -e
source "../.env"
DOMAIN=$(echo "$DOMAIN")
# mkcert -install "${DOMAIN}"

###
# Create root CA & Private key
openssl req -x509 \
            -sha256 -days 356 \
            -nodes \
            -newkey rsa:2048 \
            -subj "/CN=${DOMAIN}/C=US/L=San Fransisco" \
            -keyout rootCA.key -out rootCA.crt 

# Generate Private key 
openssl genrsa -out ${DOMAIN}.key 2048

# Create csf conf -- modify as needed
cat > csr.conf <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C="XX"
ST="Country"
L="City"
O="OrgName"
OU="Service"
emailAddress="yourmail@mail.com"
CN=${DOMAIN}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = www.${DOMAIN}

EOF

# create CSR request using private key
openssl req -new -key ${DOMAIN}.key -out ${DOMAIN}.csr -config csr.conf

# Create a external config file for the certificate
cat > cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}

EOF

# Create SSl with self signed CA
openssl x509 -req \
    -in ${DOMAIN}.csr \
    -CA rootCA.crt -CAkey rootCA.key \
    -CAcreateserial -out ${DOMAIN}.crt \
    -days 365 \
    -sha256 -extfile cert.conf

# Copy certificates to ../certs
mkdir -p ../certs
find . -type f -name "*.pem" -exec mv {} ../certs \;
