#!/usr/bin/env bash

set -e

CA_FILE=${1}
CERT_FILE=${2}
KEY_FILE=${3}
NAME=${4}

[[ -z "${CA_FILE}" || -z "${CERT_FILE}" || -z "${KEY_FILE}" || -z "${NAME}" ]] && {
  echo "Usage: $0 ca_file.pem cert_file.pem key_file.pem cert_name"
  echo
  echo "key format should be rsa"
  echo "cert_file.pem should include only one certificate"
  echo

  exit 1
}

[[ ! -f "$CA_FILE" || ! -f "${CERT_FILE}" || ! -f "${KEY_FILE}" ]] && {
  echo "files not found"

  exit 1
}

TRUSTSTORE_FILE=${NAME}.truststore.jks
KEYSTORE_FILE=${NAME}.keystore.jks
P12_FILE=${NAME}.p12

[[ -f "${KEYSTORE_FILE}" || -f "$TRUSTSTORE_FILE" || -f "${P12_FILE}" ]] && {
  echo "already have files ${KEYSTORE_FILE}, ${TRUSTSTORE_FILE} and ${P12_FILE}"
  echo ""
  echo "if you want to regenerate remove them first"
  echo "rm ${KEYSTORE_FILE} ${TRUSTSTORE_FILE} ${P12_FILE}"

  exit 1
}

TRUSTSTORE_PASSWORD=$(head -c 32 /dev/random | base64 | head -c 10)
TRUSTSTORE_PASS_FILE="${NAME}.truststore.pas"
echo "$TRUSTSTORE_PASSWORD" | cat >"${TRUSTSTORE_PASS_FILE}"
echo "Generating truststore password to ${TRUSTSTORE_PASS_FILE} ..."

KEYSTORE_PASSWORD=$(head -c 32 /dev/random | base64 | head -c 10)
KEYSTORE_PASS_FILE="${NAME}.keystore.pas"
echo "$KEYSTORE_PASSWORD" | cat >"${KEYSTORE_PASS_FILE}"
echo "Generating keystore password to ${KEYSTORE_PASS_FILE} ..."

KEY_PASSWORD=$(head -c 32 /dev/random | base64 | head -c 10)
KEY_PASS_FILE="${NAME}.key.pas"
echo "$KEY_PASSWORD" | cat >"${KEY_PASS_FILE}"
echo "Generating key password to ${KEY_PASS_FILE} ..."

KEY_ENC_FILE=${NAME}.key.enc.pem

echo "encoding private key ${KEY_FILE} to ${KEY_ENC_FILE} ..."
openssl rsa -aes256 -in "${KEY_FILE}" -out "${KEY_ENC_FILE}" \
  -passout pass:"$(cat "${KEY_PASS_FILE}")"

echo "generating ${P12_FILE} container for key and certificate ..."
openssl pkcs12 -export -in "${CERT_FILE}" -inkey "${KEY_ENC_FILE}" -CAfile "${CA_FILE}" \
  -passin pass:"${KEY_PASSWORD}" \
  -passout pass:"${KEYSTORE_PASSWORD}" \
  -out "${P12_FILE}" -name "${NAME}"

echo "converting ${P12_FILE} to JKS type ${KEYSTORE_FILE}"
keytool -importkeystore \
  -srckeystore "${P12_FILE}" \
  -srcstorepass "${KEYSTORE_PASSWORD}" \
  -srcstoretype pkcs12 \
  -srcalias "$NAME" \
  -destkeystore "${KEYSTORE_FILE}" \
  -deststorepass "${KEYSTORE_PASSWORD}" \
  -destkeypass "${KEY_PASSWORD}" \
  -deststoretype JKS \
  -destalias "${NAME}" \
  -noprompt \
  2>/dev/null

echo "process CA full chain ..."
TEMP_PREFIX="tmp-$(openssl rand -hex 12)-ca-"

openssl crl2pkcs7 -certfile "${CA_FILE}" -nocrl |
  openssl pkcs7 -print_certs |
  awk 'BEGIN{RS=""}{ f = "'"${TEMP_PREFIX}"'" NR ".pem"; print > f; close(f) }'

COUNTER=1
for ca_file in "${TEMP_PREFIX}"*.pem; do
  COMMON_NAME=$(
    openssl x509 -noout -subject -in "${ca_file}" -nameopt multiline |
      awk -F' = ' '/commonName/ {print $2}'
  )
  echo "process CA commonName = ${COMMON_NAME} ..."

  echo "import CA commonName ${COMMON_NAME} certificate to ${KEYSTORE_FILE}"
  keytool -import -noprompt -keystore "${KEYSTORE_FILE}" \
    -storepass "${KEYSTORE_PASSWORD}" -keypass "${KEY_PASSWORD}" \
    -storetype JKS -alias "${COMMON_NAME} ${COUNTER}" -file "${ca_file}" \
    2>/dev/null

  echo "import CA commonName ${COMMON_NAME} certificate to ${TRUSTSTORE_FILE}"
  keytool -import -noprompt -keystore "${TRUSTSTORE_FILE}" \
    -storepass "${TRUSTSTORE_PASSWORD}" -storetype JKS \
    -alias "${COMMON_NAME} ${COUNTER}" -file "${ca_file}" \
    2>/dev/null

  ((COUNTER++))

done

rm "${TEMP_PREFIX}"*.pem

echo "generate ${NAME}.properties"
cat >"${NAME}.properties" <<_EOF_
security.protocol=SSL
ssl.keystore.location=${KEYSTORE_FILE}
ssl.keystore.password=${KEYSTORE_PASSWORD}
ssl.key.password=${KEY_PASSWORD}
ssl.truststore.location=${TRUSTSTORE_FILE}
ssl.truststore.password=${TRUSTSTORE_PASSWORD}
ssl.enabled.protocols=TLSv1.2,TLSv1.1,TLSv1
# ssl.endpoint.identification.algorithm=none
_EOF_
