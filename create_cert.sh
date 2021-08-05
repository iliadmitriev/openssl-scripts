#!env bash

# exit on error
set -e


OPENSSL=$(brew --prefix)/opt/openssl@1.1/bin/openssl

# Use your own domain name
# domain for
# ROOT - name for root CA key and certificate files
ROOT=root

# NAME - name for personal key, certificate-signing request and certificate files
NAME=${2:-"localhost"}

CN=${1:-"localhost.ca"}

######################
# Create CA-signed certs
######################


# Generate a private key
echo "Generating personal private key ..."
${OPENSSL} genrsa -out $NAME.key 2048

# Create a certificate-signing request
echo "Generating personal certificate signing request ..."
${OPENSSL} req -new -key $NAME.key -out $NAME.csr -config certificate.conf \
   -addext "subjectAltName=DNS:${CN}" \
   -subj "/C=US/ST=NY/L=New York/O=Localhost CA, LLC/OU=Dev/CN=${CN}/emailAddress=admin@${CN}"

# Create the signed certificate
echo "Generating personal certificate ..."
${OPENSSL} x509 -req -in $NAME.csr -CA $ROOT.pem -CAkey $ROOT.key -passin file:${ROOT}.pas -CAcreateserial \
        -out $NAME.pem -days 825 -sha256 \
	-extensions x509_ext -extfile certificate.conf


echo "###############################################"
echo "File ${NAME}.key is your personal key"
echo "File ${NAME}.pem is your personal certificate"
echo "File ${ROOT}.pem is a CA bundle"
echo "###############################################"

