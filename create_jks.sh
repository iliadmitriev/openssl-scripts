# --------------- CA + keystore --------------------

# generate CA key and root certificate
# using create_ca.sh

# import CA root certificate to trustsore server and client truststore
keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file root.pem 
keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file root.pem

# --------------- server --------------------

# generate server key and certificate request
keytool -keystore kafka.server.keystore.jks -alias localhost -validity 365 -genkey -keyalg RSA
keytool -keystore kafka.server.keystore.jks -alias localhost -certreq -file kafka.server.req

# sign server certificate
openssl x509 -req -CA root.pem -CAkey root.key -in kafka.server.req -out kafka.server.pem -days 365 -CAcreateserial 

# import CA root certificate signed certificate keystore to server keystore
keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file root.pem
keytool -keystore kafka.server.keystore.jks -alias localhost -import -file kafka.server.pem


# --------------- client --------------------

# generate client key and certificate request
keytool -keystore kafka.client.keystore.jks -alias localhost -validity 365 -genkey -keyalg RSA
keytool -keystore kafka.client.keystore.jks -alias localhost -certreq -file kafka.client.req

# sign client certificate
openssl x509 -req -CA root.pem -CAkey root.key -in kafka.client.req -out kafka.client.pem -days 365 -CAcreateserial


# импортируем CA серт и подписанный серт к keystore клиента1
keytool -keystore kafka.client.keystore.jks -alias CARoot -import -file root.pem
keytool -keystore kafka.client.keystore.jks -alias localhost -import -file kafka.client.pem

