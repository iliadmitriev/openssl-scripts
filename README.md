# Self-signed certificate

This script is written in bash and openssl based. Its purpose is creation of root Certificate Authority (CA)
and self signed certificate


## Usage
1. checkout repository
2. change permissions
```shell
chmod a+x create.sh
```
3. edit `certificate.conf` `[alt_names]` section
set altenative dns names and ip addresses
4. run script
```shell
./create.sh
```
or
```shell
bash create.sh
```
5. edit subj (if needed) 
6. script will generate files:
* root.key - root CA key (needed to issue new personal certificates, passphrase protected, keep it secret)
* root.pas - a passphrase for root.key (keep it safe and secret)
* root.pem - root CA certificate, it needs to be added to System, and make it trusted
* root.srl - serial number of certificate
* localhost.key - your personal key
* localhost.pem - your personal certificate


## Check certificate authentication

### Server

```shell
openssl s_server -accept 443 -cert localhost.pem -key localhost.key -CAfile root.pem -www -state -verify_return_error -Verify 1
```

### Client

```shell
curl --cert localhost.pem --key localhost.key --cacert root.pem https://localhost:443/
```
or
```shell
openssl s_client -key localhost.key -cert localhost.pem -CAfile root.pem -connect localhost:443  
```

## Cleanup

remove root CA certificate and key, remove personal certificate, key
```shell
rm *.key *.pem *.srl *.csr *.pas
```
