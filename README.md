# Self-signed certificate

This script is written in bash and openssl based. Its purpose is creation of root Certificate Authority (CA)
and issue self-signed certificates

Recommended version of openssl is 1.1.1
For macOS it's better to use version from homebrew

## Usage
1. checkout repository
2. change permissions
```shell
chmod a+x create_ca.sh create_cert.sh
```
3. establish new CA, running script with specifying domain name of root CA
```shell
./create_ca.sh hello.com
```
* `root.key` - root CA key (needed to issue new personal certificates, passphrase protected, keep it secret)
* `root.pas` - a passphrase for root.key (keep it safe and secret)
* `root.pem` - root CA certificate, it needs to be added to System, and make it trusted
* `root.srl` - serial number of certificate
if you run script again previous versions of files will be overwritten
4. add `root.pem` to your system trusted certificates
5. create your personal certificate
```shell
./create_cert.sh hello-world.info
```
* `hello-world.info.key` - your personal key
* `hello-world.info.pem` - your personal certificate


## Check certificate chain

```shell
openssl verify -show_chain -CAfile root.pem hello-world.info.pem
```

## Check certificate authentication

### Server

```shell
openssl s_server -accept 443 -cert hello-world.info.pem \
    -key hello-world.info.key -CAfile root.pem \
    -www -state -verify_return_error -Verify 1
```

### Client

```shell
curl --cert hello-world.info.pem --key hello-world.info.key \
      --cacert root.pem https://hello-world.info/
```
or
```shell
echo "GET / HTTP/1.1\n\r" | openssl s_client -key hello-world.info.key \
  -cert hello-world.info.pem -CAfile root.pem -connect hello-world.info:443  
```

## Cleanup

remove root CA certificate and key, remove personal certificate, key
```shell
rm *.key *.pem *.srl *.csr *.pas
```
