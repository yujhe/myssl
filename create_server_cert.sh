#!/bin/bash -e

cd "`dirname "$0"`"

ca_dir=ca/inter
server_dir=server
version=`date -u +"%Y%m%d_%H%M%S"` # 20200101_235959

#
# server
# ├── archive
# │   ├── chained.cert.pem.20190101_235959
# │   ├── server.cert.pem.20190101_235959
# │   ├── server.csr.pem.20190101_235959
# │   └── server.key.pem.20190101_235959
# ├── chained.cert.pem.20200101_235959
# ├── chained.cert.pem.latest -> chained.cert.pem.20200101_235959
# ├── server.cert.pem.20200101_235959
# ├── server.cert.pem.latest -> server.cert.pem.20200101_235959
# ├── server.csr.pem.20200101_235959
# ├── server.csr.pem.latest -> server.csr.pem.20200101_235959
# ├── server.key.pem.20200101_235959
# └── server.key.pem.latest -> server.key.pem.20200101_235959
#

# create necessary direcrory
mkdir -p $server_dir $server_dir/archive

if [ ! -f $ca_dir/ca.cert.pem.latest ]; then
  echo "$ca_dir/ca.cert.pem.latest not found"
  exit 1
fi

# create private key and csr
echo "create private key and csr"
openssl req \
  -new \
  -keyout $server_dir/server.key.pem.$version \
  -out $server_dir/server.csr.pem.$version \
  -subj "/CN=server.$version/OU=na/O=na/L=na/ST=na/C=tw" \
  -nodes

# sign certificate by intermediate ca (expired after 180 days)
echo "sign certificate by intermediate ca"
openssl ca \
  -config inter.openssl.cnf \
  -keyfile $ca_dir/ca.key.pem.latest \
  -cert $ca_dir/ca.cert.pem.latest \
  -in $server_dir/server.csr.pem.$version \
  -out $server_dir/server.cert.pem.$version \
  -days 180 \
  -notext \
  -batch \
  -extensions server_cert

# create certificate chain
cat $server_dir/server.cert.pem.$version $ca_dir/chained.cert.pem.latest > $server_dir/chained.cert.pem.$version

cd $server_dir

# moving old ca into archive directory
shopt -s nullglob
for f in *.latest; do
  echo "move $server_dir/$f -> $server_dir/$(readlink $f)"
  mv $(readlink $f) archive/
done

# link the created certificate to latest
ln -sf server.cert.pem.$version server.cert.pem.latest
ln -sf server.key.pem.$version server.key.pem.latest
ln -sf server.csr.pem.$version server.csr.pem.latest
ln -sf chained.cert.pem.$version chained.cert.pem.latest

