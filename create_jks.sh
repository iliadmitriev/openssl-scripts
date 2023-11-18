# --------------- CA + keystore --------------------

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
echo $TRUSTSTORE_PASSWORD | cat > ${NAME}.truststore.pas
echo "Generating keystore password to ${NAME}.keystore.pas ..."

KEYSTORE_PASSWORD=$(head -c 32 /dev/random | base64 | head -c 10)
echo $KEYSTORE_PASSWORD | cat > ${NAME}.keystore.pas
echo "Generating keystore password to ${NAME}.keystore.pas ..."

KEY_PASSWORD=$(head -c 32 /dev/random | base64 | head -c 10)
echo $KEY_PASSWORD | cat > ${NAME}.key.pas
echo "Generating key password to ${NAME}.key.pas ..."

# import CA root certificate to trustsore
keytool -import -noprompt -keystore ${NAME}.truststore.jks \
    -storepass "${TRUSTSTORE_PASSWORD}" -storetype JKS \
    -alias CARoot -file root.pem \
    -ext SAN:DNS:${HOSTNAME} \
    2>/dev/null

# --------------- server --------------------

# generate key
keytool -genkey -noprompt -keystore ${NAME}.keystore.jks \
    -storepass ${KEYSTORE_PASSWORD} -keypass ${KEY_PASSWORD} -storetype JKS \
    -alias localhost -keysize 2048 -validity 825 -keyalg RSA \
    -dname "CN=${HOSTNAME}, OU=Dev, O=ORG, L=Moscow, ST=MSK, C=RU" \
    2>/dev/null

# generate certificate signing request
keytool -certreq -noprompt -keystore ${NAME}.keystore.jks \
    -storepass ${KEYSTORE_PASSWORD} -keypass ${KEY_PASSWORD} -storetype JKS \
    -alias localhost -file ${NAME}.cert.req \
    2>/dev/null

# sign server certificate
openssl x509 -req -CA root.pem -CAkey root.key -in ${NAME}.cert.req \
    -passin file:${ROOT}.pas -out ${NAME}.cert.pem -days 825 -CAcreateserial

# import CA root certificate signed certificate keystore to server keystore
keytool -import -noprompt -keystore ${NAME}.keystore.jks \
    -storepass ${KEYSTORE_PASSWORD} -keypass ${KEY_PASSWORD} \
    -storetype JKS -alias CARoot -file root.pem \
    2>/dev/null
keytool -import -noprompt -keystore ${NAME}.keystore.jks \
    -storepass ${KEYSTORE_PASSWORD} -keypass ${KEY_PASSWORD} \
    -storetype JKS -alias localhost -file ${NAME}.cert.pem \
    2>/dev/null
