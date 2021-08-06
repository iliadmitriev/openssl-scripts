#!env bash

# exit on error
set -e

# where is your openssl resides
OPENSSL=$(brew --prefix)/opt/openssl@1.1/bin/openssl

# ROOT - name for root CA key and certificate files
ROOT=root

# CN - canonical name (ex. google.com)
CN=${1:-"localhost.ca"}

# NAME - name for personal key, certificate-signing request and certificate files
NAME=${2:-${CN}}

######################
# Create CA-signed certs
######################


# Generate a private key
# echo "Generating personal private key ..."
${OPENSSL} genrsa -out $NAME.key 2048

# template for config file
conf_template="$(cat certificate.conf.tpl)"
conf_template=$(sed 's/\([^\\]\)"/\1\\"/g; s/^"/\\"/g' <<< "${conf_template}")

# Create a certificate-signing request
echo "Generating personal certificate signing request ..."
${OPENSSL} req -new -key $NAME.key -out $NAME.csr -config <(eval "echo \"${conf_template}\"") \
   -addext "subjectAltName=DNS:${CN}" \
   -subj "/C=US/ST=NY/L=New York/O=Localhost CA, LLC/OU=Dev/CN=${CN}/emailAddress=admin@${CN}"

# Create the signed certificate
echo "Generating personal certificate ..."
${OPENSSL} x509 -req -in $NAME.csr -CA $ROOT.pem -CAkey $ROOT.key -passin file:${ROOT}.pas -CAcreateserial \
  -out $NAME.pem -days 825 -sha256 \
	-extensions x509_ext -extfile  <(eval "echo \"${conf_template}\"")


echo "###############################################"
echo "File ${NAME}.key is your personal key"
echo "File ${NAME}.pem is your personal certificate"
echo "File ${ROOT}.pem is a CA bundle"
echo "###############################################"

