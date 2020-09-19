#!/bin/bash -e

cd "`dirname "$0"`"

ca_dir=ca/root
version=`date -u +"%Y%m%d_%H%M%S"` # 20200101_235959

#
# ca/root
# ├── archive
# │   ├── ca.cert.pem.20190101_235959
# │   ├── ca.crl.pem.20190101_235959
# │   └── ca.key.pem.20190101_235959
# ├── ca.cert.pem.20200101_235959
# ├── ca.cert.pem.latest -> ca.cert.pem.20200101_235959
# ├── ca.crl.pem.20200101_235959
# ├── ca.crl.pem.latest -> ca.crl.pem.20200101_235959
# ├── ca.key.pem.20200101_235959
# ├── ca.key.pem.latest -> ca.key.pem.20200101_235959
# ├── crlnumber
# ├── index.txt
# ├── newcerts/
# └── serial
#

# create necessary file and directory
mkdir -p $ca_dir $ca_dir/newcerts $ca_dir/archive

if [ ! -f $ca_dir/index.txt ]; then
  # database to record signed certificate
  touch $ca_dir/index.txt
fi
if [ ! -f $ca_dir/serial ]; then
  # initial serial number
  echo 1000 > $ca_dir/serial
fi
if [ ! -f $ca_dir/crlnumber ]; then
  # initial crl number
  echo 1000 > $ca_dir/crlnumber
fi

# create private key and ca (expired after 10 years)
echo "create private key and ca under $ca_dir/"
openssl req \
  -config root.openssl.cnf \
  -new \
  -x509 \
  -keyout $ca_dir/ca.key.pem.$version \
  -out $ca_dir/ca.cert.pem.$version \
  -days 3650 \
  -subj "/CN=root_ca.$version/OU=na/O=na/L=na/ST=na/C=tw" \
  -nodes

# create an empty crl file
echo "create an empty crl file"
openssl ca \
  -config root.openssl.cnf \
  -gencrl \
  -keyfile $ca_dir/ca.key.pem.$version \
  -cert $ca_dir/ca.cert.pem.$version \
  -out $ca_dir/ca.crl.pem.$version

cd $ca_dir

# archive old ca
shopt -s nullglob
for f in *.latest; do
  echo "move $ca_dir/$f -> $ca_dir/$(readlink $f)"
  mv $(readlink $f) archive/
done

# link the created ca to latest
ln -sf ca.cert.pem.$version ca.cert.pem.latest
ln -sf ca.key.pem.$version ca.key.pem.latest
ln -sf ca.crl.pem.$version ca.crl.pem.latest

