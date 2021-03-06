[req]
default_bits       = 2048
default_keyfile    = root.key
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = x509_ext


[req_distinguished_name]
countryName                 = Country Name (2 letter code)
countryName_default         = US
stateOrProvinceName         = State or Province Name (full name)
stateOrProvinceName_default = NY
localityName                = Locality Name (eg, city)
localityName_default        = New York
organizationName            = Organization Name (eg, company)
organizationName_default    = Localhost, LLC
organizationalUnitName      = organizationalunit
organizationalUnitName_default = Dev
commonName                  = Common Name (e.g. server FQDN or YOUR name)
commonName_default          = localhost
commonName_max              = 64
emailAddress                = Email Address
emailAddress_default        = admin@localhost


# req_ext is used when generating a certificate signing request.
[req_ext]
subjectKeyIdentifier        = hash
basicConstraints            = CA:FALSE
keyUsage                    = digitalSignature, keyEncipherment, keyAgreement
extendedKeyUsage            = serverAuth, clientAuth, codeSigning, emailProtection, timeStamping, OCSPSigning
subjectAltName = @alt_names


# x509_ext is used when generating a self-signed certificate.
[x509_ext]
subjectKeyIdentifier        = hash
authorityKeyIdentifier      = keyid,issuer
basicConstraints            = CA:FALSE
keyUsage                    = digitalSignature, keyEncipherment, keyAgreement
extendedKeyUsage            = serverAuth, clientAuth, codeSigning, emailProtection, timeStamping, OCSPSigning
subjectAltName = @alt_names


[alt_names]
DNS.1   = ${CN}
DNS.2   = localhost
DNS.3   = localhost.tld
DNS.4   = localhost.localdomain

DNS.5   = 127.0.0.1
DNS.6   = 192.168.10.1
DNS.7   = 192.168.1.89
DNS.8   = 192.168.1.90

# For chrome compatibility
IP.1       = 127.0.0.1
IP.2       = 192.168.10.1
IP.3       = 192.168.1.89
IP.4       = 192.168.1.90
