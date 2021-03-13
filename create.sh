!env bash

# exit on error
set -e

# Use your own domain name
# domain for
# ROOT - name for root CA key and certificate files
ROOT=root
# NAME - name for personal key, certificate-signing request and certificate files
NAME=localhost


######################
# Create a Certificate Authority
######################
 
# Generate private key
echo "Generating CA root private key ..."
openssl genrsa -des3 -out $ROOT.key 2048 -config ca.conf

# Generate root certificate
echo "Generating CA root certificate ..."
openssl req -x509 -new -nodes -key $ROOT.key -sha256 -days 825 -out $ROOT.pem \
 -config ca.conf

echo "Keep ${ROOT}.key in secret place, don't loose its password"
echo "Add ${ROOT}.pem root certificate to System, and make it trusted"


######################
# Create CA-signed certs
######################


# Generate a private key
echo "Generating personal private key ..."
openssl genrsa -out $NAME.key 2048 -config certificate.conf

# Create a certificate-signing request
echo "Generating personal certificate signing request ..."
openssl req -new -key $NAME.key -out $NAME.csr -config certificate.conf

# Create the signed certificate
echo "Generating personal certificate ..."
openssl x509 -req -in $NAME.csr -CA $ROOT.pem -CAkey $ROOT.key -CAcreateserial \
-out $NAME.pem -days 825 -sha256 -extfile certificate.conf
