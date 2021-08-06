#!env bash

# exit on error
set -e

# Use your own domain name
# domain for
# ROOT - name for root CA key and certificate files
ROOT=root.gost
# NAME - name for personal key, certificate-signing request and certificate files
NAME=localhost.gost
OPENSSL=$(brew --prefix)/opt/openssl@1.1/bin/openssl

$OPENSSL engine gost 2>&1 > /dev/null || { echo "openssl@1.1 with GOST 34.11 2012 is not installed" ; \
 echo "please check https://github.com/iliadmitriev/how-to-docs/blob/main/OPENSSL_GOST_MAC.md" ; exit 1; }

######################
# Create a Certificate Authority
######################

# Generate private key
echo "Generating CA root private key ..."
$OPENSSL genpkey -algorithm gost2012_256 \
       -pkeyopt paramset:A -out $ROOT.key 

# Generate root certificate
echo "Generating CA root certificate ..."
$OPENSSL req -x509 -new -nodes -key $ROOT.key -md_gost12_256 -days 825 -out $ROOT.pem \
   -subj "/C=US/ST=NY/L=New York/O=Localhost CA, LLC/OU=Dev/CN=localhost.ca/emailAddress=admin@localhost.ca" \
   -config ca.conf


echo "###############################################"
echo "Keep ${ROOT}.key in secret place, don't loose its password"
echo "Add ${ROOT}.pem root certificate to System, and make it trusted"
echo "###############################################"


######################
# Create CA-signed certs
######################


# Generate a private key
echo "Generating personal private key ..."
$OPENSSL genpkey -algorithm gost2012_256 -pkeyopt paramset:A \
            -out $NAME.key

# Create a certificate-signing request
echo "Generating personal certificate signing request ..."
$OPENSSL req -new -key $NAME.key -out $NAME.csr -md_gost12_256 -config certificate.conf \
   -subj "/C=US/ST=NY/L=New York/O=Localhost CA, LLC/OU=Dev/CN=localhost.ca/emailAddress=admin@localhost.ca"

# Create the signed certificate
echo "Generating personal certificate ..."
$OPENSSL x509 -req -in $NAME.csr -CA $ROOT.pem -CAkey $ROOT.key \
        -md_gost12_256 -CAcreateserial \
        -out $NAME.pem -days 825 -extensions x509_ext -extfile certificate.conf

