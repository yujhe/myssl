#!/bin/bash -e

cd "`dirname "$0"`"

ca_dir=ca/inter
root_ca_dir=ca/root
version=`date -u +"%Y%m%d_%H%M%S"` # 20200101_235959

#
# ca/inter
# ├── archive
# │   ├── ca.cert.pem.20190101_235959
# │   ├── ca.crl.pem.20190101_235959
# │   ├── ca.csr.pem.20190101_235959
# │   ├── ca.key.pem.20190101_235959
# │   └── chained.cert.pem.20190101_235959
# ├── ca.cert.pem.20200101_235959
# ├── ca.cert.pem.latest -> ca.cert.pem.20200101_235959
# ├── ca.crl.pem.20200101_235959
# ├── ca.crl.pem.latest -> ca.crl.pem.20200101_235959
# ├── ca.csr.pem.20200101_235959
# ├── ca.csr.pem.latest -> ca.csr.pem.20200101_235959
# ├── ca.key.pem.20200101_235959
# ├── ca.key.pem.latest -> ca.key.pem.20200101_235959
# ├── chained.cert.pem.20200101_235959
# ├── chained.cert.pem.latest -> chained.cert.pem.20200101_235959
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
if [ ! -f $root_ca_dir/ca.cert.pem.latest ]; then
  echo "$root_ca_dir/ca.cert.pem.latest not found"
  exit 1
fi

# create private key and csr
echo "create private key and csr"
openssl req \
  -newkey rsa:2048 \
  -keyout $ca_dir/ca.key.pem.$version \
  -out $ca_dir/ca.csr.pem.$version \
  -subj "/CN=inter_ca.$version/OU=na/O=na/L=na/ST=na/C=tw" \
  -nodes

# sign certificate by root ca (expired after 2 years)
echo "sign certificate by root ca"
openssl ca \
  -config root.openssl.cnf \
  -keyfile $root_ca_dir/ca.key.pem.latest \
  -cert $root_ca_dir/ca.cert.pem.latest \
  -in $ca_dir/ca.csr.pem.$version \
  -out $ca_dir/ca.cert.pem.$version \
  -days 730 \
  -notext \
  -batch \
  -extensions v3_intermediate_ca

# create an empty crl file
echo "create an empty crl file"
openssl ca \
  -config inter.openssl.cnf \
  -gencrl \
  -keyfile $ca_dir/ca.key.pem.$version \
  -cert $ca_dir/ca.cert.pem.$version \
  -out $ca_dir/ca.crl.pem.$version

# create certificate chain
cat $ca_dir/ca.cert.pem.$version $root_ca_dir/ca.cert.pem.latest > $ca_dir/chained.cert.pem.$version

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
ln -sf ca.csr.pem.$version ca.csr.pem.latest
ln -sf chained.cert.pem.$version chained.cert.pem.latest

