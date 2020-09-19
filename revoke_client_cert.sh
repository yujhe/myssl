#!/bin/bash -e

if [ -z "$1" ]; then
  client_cert=client/client.cert.pem.latest
else
  client_cert=$1
fi

# get ca version from client certificate issuer
ca_version=$(openssl x509 -in $client_cert -issuer -noout | sed 's/issuer=.*inter_ca.\([0-9_]*\).*$/\1/g')

# check client certificate is signed by the latest ca
latest_ca_file=$(readlink ca/inter/ca.cert.pem.latest)
latest_ca_version=${latest_ca_file##*.}
if [ "$ca_version" = "$latest_ca_version" ]; then
  ca_dir=ca/inter
else
  ca_dir=ca/inter/archive
fi

# revoke client certificate
echo "revoke client certificate $client_cert"
openssl ca \
  -config inter.openssl.cnf \
  -keyfile $ca_dir/ca.key.pem.$ca_version \
  -cert $ca_dir/ca.cert.pem.$ca_version \
  -revoke $client_cert

# update crl
echo "update $ca_dir/ca.crl.pem.$ca_version"
openssl ca \
  -config inter.openssl.cnf \
  -gencrl \
  -keyfile $ca_dir/ca.key.pem.$ca_version \
  -cert $ca_dir/ca.cert.pem.$ca_version \
  -out $ca_dir/ca.crl.pem.$ca_version

