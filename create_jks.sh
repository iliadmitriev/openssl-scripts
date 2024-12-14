#!/usr/bin/env bash
# --------------- CA + trustsore --------------------

# generate CA key and root certificate
# using create_ca.sh

ROOT=root
NAME=${1}
HOSTNAME=${2}

[[ -z "${NAME}" || -z "${HOSTNAME}" ]] && {
	echo "Usage: $0 <name> <hostname>"
	echo "example: $0 client example.org"
	exit
}

TRUSTSTORE_PASSWORD=$(head -c 32 /dev/random | base64 | head -c 10)
echo "$TRUSTSTORE_PASSWORD" | cat >"${NAME}.truststore.pas"
echo "Generating truststore password to ${NAME}.truststore.pas ..."

KEYSTORE_PASSWORD=$(head -c 32 /dev/random | base64 | head -c 10)
echo "$KEYSTORE_PASSWORD" | cat >"${NAME}.keystore.pas"
echo "Generating keystore password to ${NAME}.keystore.pas ..."

KEY_PASSWORD=$(head -c 32 /dev/random | base64 | head -c 10)
echo "$KEY_PASSWORD" | cat >"${NAME}.key.pas"
echo "Generating key password to ${NAME}.key.pas ..."

# import CA root certificate to trustsore
keytool -import -noprompt -keystore "${NAME}.truststore.jks" \
	-storepass "${TRUSTSTORE_PASSWORD}" -storetype JKS \
	-alias CARoot -file root.pem \
	-ext "SAN:DNS:${HOSTNAME}" \
	2>/dev/null

# --------------- keystore --------------------

# generate key
keytool -genkey -noprompt -keystore "${NAME}.keystore.jks" \
	-storepass "${KEYSTORE_PASSWORD}" -keypass "${KEY_PASSWORD}" -storetype JKS \
	-alias localhost -keysize 2048 -validity 825 -keyalg RSA \
	-dname "CN=${HOSTNAME}, OU=Dev, O=ORG, L=Moscow, ST=MSK, C=RU" \
	2>/dev/null

# generate certificate signing request
keytool -certreq -noprompt -keystore "${NAME}.keystore.jks" \
	-storepass "${KEYSTORE_PASSWORD}" -keypass "${KEY_PASSWORD}" -storetype JKS \
	-alias localhost -file "${NAME}.cert.req" \
	-ext SubjectAlternativeName="DNS:${HOSTNAME}" \
	-ext BasicConstraints=CA:false \
	-ext KeyUsage=keyEncipherment,digitalSignature \
	-ext ExtendedKeyUsage=clientAuth,serverAuth \
	2>/dev/null

cat >"${NAME}.x509_v3_ext.cnf" <<_EOF_
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${HOSTNAME}
_EOF_

# sign server certificate
openssl x509 -req -CA root.pem -CAkey root.key -in "${NAME}.cert.req" \
	-passin "file:${ROOT}.pas" -out "${NAME}.cert.pem" -days 825 -CAcreateserial \
	-extfile "${NAME}.x509_v3_ext.cnf"

# import CA root certificate signed certificate keystore to server keystore
keytool -import -noprompt -keystore "${NAME}.keystore.jks" \
	-storepass "${KEYSTORE_PASSWORD}" -keypass "${KEY_PASSWORD}" \
	-storetype JKS -alias CARoot -file root.pem \
	2>/dev/null
keytool -import -noprompt -keystore "${NAME}.keystore.jks" \
	-storepass "${KEYSTORE_PASSWORD}" -keypass "${KEY_PASSWORD}" \
	-storetype JKS -alias localhost -file "${NAME}.cert.pem" \
	2>/dev/null

# export keystore to PKCS12 and key to PEM
keytool -importkeystore  \
   -srckeystore "${NAME}.keystore.jks" \
   -srcstorepass "${KEYSTORE_PASSWORD}" \
   -srckeypass "${KEY_PASSWORD}" \
   -srcalias localhost \
   -destkeystore "${NAME}.p12" \
   -deststorepass "${KEYSTORE_PASSWORD}" \
   -deststoretype pkcs12 -noprompt

openssl pkcs12 -in "${NAME}.p12" -nodes -noenc -nocerts -passin pass:"${KEYSTORE_PASSWORD}" > "${NAME}.key.pem"


rm "${NAME}.x509_v3_ext.cnf"
