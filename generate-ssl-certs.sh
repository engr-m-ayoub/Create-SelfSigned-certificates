#!/bin/sh
#
# this is a script that will generate openssl x509 self signed certifcates
#	

if  [ ! -f /usr/lib/ssl/openssl.cnf ]; then
	echo "openssl config doesnot exist. please reinstall"
fi

if [ "$#" -ne 2 ]; then
	echo "expects two arguments: hostname cert_path"
	exit 1;
fi

hostname=$1
path=$2
echo $hostname $path

if [ ! -f /root/ca/private/cakey.pem ] || [ ! -f /root/ca/cacert.pem ]; then

	echo "setting up CA"

	# update openssl conf file for ca dir
	sed -i 's/.\/demoCA/\/root\/ca/' /usr/lib/ssl/openssl.cnf

	# setup ca hierarchy
	mkdir -p /root/ca && cd /root/ca/
	#nano /etc/hosts (set host name if not set)
	mkdir -p newcerts certs crl private requests

	touch index.txt serial
	echo '1234' > serial

	# generate ca key and certificate
	echo "generate CA key"
	openssl genrsa -aes256 -passout pass:SZNEe62D -out private/cakey.pem 4096
	echo "generate CA cert valid for 10 years"
	openssl req -new -x509 -key /root/ca/private/cakey.pem -subj '/C=US/ST=CA/L=Las Vegas/O=Ebryx/CN=SDP' -passin pass:SZNEe62D -out cacert.pem -days 3650

	#convert in from 'crt' to 'cer' format
	openssl x509 -inform PEM -in cacert.pem -outform der -out cacert.cer

	chmod 600 -R /root/ca/
	echo "CA self signed certificate signing authority setup successfully."

elif grep -Fq "demoCA"  /usr/lib/ssl/openssl.cnf; then
	echo "CA already setup but openssl configuration needs to be setup again as it has been restored to default. (Probably package updated.)"
	# update openssl conf file for ca dir
	sed -i 's/.\/demoCA/\/root\/ca/' /usr/lib/ssl/openssl.cnf

else
	echo "CA already setup"
fi


echo  "creating client certificate and key"
mkdir -p $path
cd $path
openssl genrsa -aes256 -passout pass:SZNEe62D -out client.pem 2048
openssl req -new -key client.pem -subj "/C=US/ST=CA/L=Las Vegas/O=Ebryx/CN=$hostname" -passin pass:SZNEe62D -out client.csr

#generate certificate in 'cer' and convert it to 'crt' format
#openssl ca -in client.csr -batch -passin pass:SZNEe62D -out client.crt
openssl ca -in client.csr -batch -passin pass:SZNEe62D -out client.cer
openssl x509 -inform PEM -in client.cer -out client.crt

#convert key to p12 format
openssl pkcs12 -export -passout pass:SZNEe62D -inkey client.pem -in client.crt -out client.p12 -passin pass:SZNEe62D


mv client.csr  /root/ca/certs/
cp /root/ca/cacert.pem /root/ca/cacert.cer $path
chmod -R +r $path
