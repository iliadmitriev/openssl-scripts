#!/usr/bin/env bash

# exit on error
set -e

OPENSSL_EXEC=openssl

# ROOT - name for root CA key and certificate files
ROOT=root

CN=${1:-"localhost.ca"}

# protection against overwriting CA root
[[ -f "root.key" || -f "root.pas" || -f "root.pem" ]] && {
  echo "It looks like that you have already created CA root"
  echo "To create it again you have to delete existing CA first"
  echo "Use command"
  echo "rm root.*"
  echo ""
  exit
}

######################
# Create a Certificate Authority
######################

# Generating password for private key encryption

echo "Generating Random password ..."
PASSWORD=$(date +%s | shasum -a 256 | base64 | head -c 16)
echo "$PASSWORD" | cat > "${ROOT}.pas"
 
# Generate private key
echo "Generating CA root private key ..."
${OPENSSL_EXEC} genrsa -des3 -passout "file:${ROOT}.pas" -out $ROOT.key 2048 

# Generate root certificate
echo "Generating CA root certificate ..."
${OPENSSL_EXEC} req -x509 -new -nodes -key "$ROOT.key" -sha256 -days 825 -out "$ROOT.pem" \
   -subj "/C=US/ST=NY/L=New York/O=Localhost CA, LLC/OU=Dev/CN=${CN}/emailAddress=admin@${CN}" \
   -passin file:${ROOT}.pas \
   -config ca.conf


echo "###############################################"
echo "File ${ROOT}.pas contains private key password"
echo "Keep ${ROOT}.key in secret place, don't loose its password"
echo "Add ${ROOT}.pem root certificate to System, and make it trusted"
echo "###############################################"


