#!/bin/bash -e

cd "`dirname "$0"`"

ca_dir=ca/inter
client_dir=client
version=`date -u +"%Y%m%d_%H%M%S"` # 20200101_235959

#
# client
# ├── archive
# │   ├── client.cert.pem.20190101_235959
# │   ├── client.csr.pem.20190101_235959
# │   ├── client.key.pem.20190101_235959
# ├── client.cert.pem.20200101_235959
# ├── client.cert.pem.latest -> client.cert.pem.20200101_235959
# ├── client.csr.pem.20200101_235959
# ├── client.csr.pem.latest -> client.csr.pem.20200101_235959
# ├── client.key.pem.20200101_235959
# └── client.key.pem.latest -> client.key.pem.20200101_235959
#

# create necessary direcrory
mkdir -p $client_dir $client_dir/archive

if [ ! -f $ca_dir/ca.cert.pem.latest ]; then
  echo "$ca_dir/ca.cert.pem.latest not found"
  exit 1
fi

# create private key and csr
echo "create private key and csr"
openssl req \
  -new \
  -keyout $client_dir/client.key.pem.$version \
  -out $client_dir/client.csr.pem.$version \
  -subj "/CN=client.$version/OU=na/O=na/L=na/ST=na/C=tw" \
  -nodes

# sign certificate by intermediate ca (expired after 30 days)
echo "sign certificate by intermediate ca"
openssl ca \
  -config inter.openssl.cnf \
  -keyfile $ca_dir/ca.key.pem.latest \
  -cert $ca_dir/ca.cert.pem.latest \
  -in $client_dir/client.csr.pem.$version \
  -out $client_dir/client.cert.pem.$version \
  -days 30 \
  -notext \
  -batch \
  -extensions usr_cert

cd $client_dir

# moving old ca into archive directory
shopt -s nullglob
for f in *.latest; do
  echo "move $client_dir/$f -> $client_dir/$(readlink $f)"
  mv $(readlink $f) archive/
done

# link the created certificate to latest
ln -sf client.cert.pem.$version client.cert.pem.latest
ln -sf client.key.pem.$version client.key.pem.latest
ln -sf client.csr.pem.$version client.csr.pem.latest

