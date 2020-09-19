#!/bin/bash -e

rm ssl/* && mkdir -p ssl

# copy server certificate which chained with ca
cp ../server/chained.cert.pem.latest ./ssl/server.chained.cert.pem
cp ../server/server.key.pem.latest ./ssl/server.key.pem

# copy ca chain
cat ../ca/inter/ca.cert.pem.latest ../ca/root/ca.cert.pem.latest > ./ssl/ca.chained.cert.pem
# copy ca chain's crl
cat ../ca/inter/ca.crl.pem.latest ../ca/root/ca.crl.pem.latest > ./ssl/ca.chained.crl.pem
