#!/bin/bash -e

ca_dir=ca/inter

client_dir=client
client_cert=${1:-$client_dir/client.cert.pem.latest}

echo "verificate client certificate $client_cert"
openssl verify \
  -crl_check \
  -CAfile <(cat $ca_dir/chained.cert.pem.latest $ca_dir/ca.crl.pem.latest $ca_dir/archive/chained.cert.pem.* $ca_dir/archive/ca.crl.pem.* 2>/dev/null) \
  $client_cert
