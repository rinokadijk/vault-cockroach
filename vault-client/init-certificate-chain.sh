#!/usr/bin/env sh

set -e

while [ $(curl -sL -w "%{http_code}\\n" "http://vault:8200/" -o /dev/null --connect-timeout 3 --max-time 5) != "200" ]
do
    echo Waiting for http://vault:8200 to be up...
    sleep 2
done

IS_INITIALIZED=$(vault status | grep Initialized | awk '{ print $2 }')
IS_SEALED=$(vault status | grep Sealed | awk '{ print $2 }')
if [[ "$IS_INITIALIZED" != "true" ]];then
    vault operator init -key-shares=1 -key-threshold=1 > /vault-token/keys.txt
    UNSEAL_KEY=$(cat /vault-token/keys.txt | grep 'Unseal Key' | awk '{ print $4 }')
    echo $UNSEAL_KEY > /vault-token/unseal.token
    ROOT_TOKEN=$(cat /vault-token/keys.txt | grep 'Initial Root Token' | awk '{ print $4 }')
    echo $ROOT_TOKEN > /vault-token/root.token
    vault operator unseal ${UNSEAL_KEY}

    vault login ${ROOT_TOKEN}
    vault secrets enable pki

    vault secrets tune -max-lease-ttl=87600h pki
    vault write -field=certificate pki/root/generate/internal \
           common_name="example.com" \
           ttl=87600h > CA_cert.crt
    vault write pki/config/urls \
           issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" \
           crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"
    vault secrets enable -path=pki_int pki
    vault secrets tune -max-lease-ttl=43800h pki_int

    vault write -format=json pki_int/intermediate/generate/internal \
           common_name="example.com Intermediate Authority" ttl="43800h" \
           | jq -r '.data.csr' > pki_intermediate.csr

    vault write -format=json pki/root/sign-intermediate csr=@pki_intermediate.csr \
           format=pem_bundle ttl="43800h" \
           | jq -r '.data.certificate' > intermediate.cert.pem

    vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem

    vault write pki_int/roles/example-dot-com \
           allowed_domains="example.com" \
           allow_subdomains=true \
           allow_any_name=true \
           max_ttl="720h"
else
    UNSEAL_KEY=$(cat /vault-token/keys.txt | grep 'Unseal Key' | awk '{ print $4 }')
    echo $UNSEAL_KEY > /vault-token/unseal.token
    ROOT_TOKEN=$(cat /vault-token/keys.txt | grep 'Initial Root Token' | awk '{ print $4 }')
    echo $ROOT_TOKEN > /vault-token/root.token
fi

if [[ "$IS_SEALED" == "true" ]];then
    vault operator unseal ${UNSEAL_KEY}
fi

echo generating new certificate for roach1
vault write -format=json pki_int/issue/example-dot-com common_name="node" alt_names="roach1" ip_sans="::" ttl="24h" > /cockroach-certs/vault_response.json
mkdir -p /cockroach-certs/roach1/
cat /cockroach-certs/vault_response.json | jq -r .data.issuing_ca > /cockroach-certs/roach1/ca.crt
cat /cockroach-certs/vault_response.json | jq -r .data.certificate > /cockroach-certs/roach1/node.crt
cat /cockroach-certs/vault_response.json | jq -r .data.private_key > /cockroach-certs/roach1/node.key
chmod 0600 /cockroach-certs/roach1/node.key

echo generating new certificate for roach2
vault write -format=json pki_int/issue/example-dot-com common_name="node" alt_names="roach2" ip_sans="::" ttl="24h" > /cockroach-certs/vault_response.json
mkdir -p /cockroach-certs/roach2/
cat /cockroach-certs/vault_response.json | jq -r .data.issuing_ca > /cockroach-certs/roach2/ca.crt
cat /cockroach-certs/vault_response.json | jq -r .data.certificate > /cockroach-certs/roach2/node.crt
cat /cockroach-certs/vault_response.json | jq -r .data.private_key > /cockroach-certs/roach2/node.key
chmod 0600 /cockroach-certs/roach2/node.key

echo generating new certificate for roach3
vault write -format=json pki_int/issue/example-dot-com common_name="node" alt_names="roach3" ip_sans="::" ttl="24h" > /cockroach-certs/vault_response.json
mkdir -p /cockroach-certs/roach3/
cat /cockroach-certs/vault_response.json | jq -r .data.issuing_ca > /cockroach-certs/roach3/ca.crt
cat /cockroach-certs/vault_response.json | jq -r .data.certificate > /cockroach-certs/roach3/node.crt
cat /cockroach-certs/vault_response.json | jq -r .data.private_key > /cockroach-certs/roach3/node.key
chmod 0600 /cockroach-certs/roach3/node.key

echo generating new certificate for root user
vault write -format=json pki_int/issue/example-dot-com common_name="root" ttl="24h" > /cockroach-certs/vault_response.json
mkdir -p /cockroach-certs/roach-client/
cat /cockroach-certs/vault_response.json | jq -r .data.issuing_ca > /cockroach-certs/roach-client/ca.crt
cat /cockroach-certs/vault_response.json | jq -r .data.certificate > /cockroach-certs/roach-client/client.root.crt
cat /cockroach-certs/vault_response.json | jq -r .data.private_key > /cockroach-certs/roach-client/client.root.key
chmod 0600 /cockroach-certs/roach-client/client.root.key

echo generating new certificate for jpointsman user
vault write -format=json pki_int/issue/example-dot-com common_name="jpointsman" ttl="24h" > /cockroach-certs/vault_response.json
cat /cockroach-certs/vault_response.json | jq -r .data.certificate > /cockroach-certs/roach-client/client.jpointsman.crt
cat /cockroach-certs/vault_response.json | jq -r .data.private_key > /cockroach-certs/roach-client/client.jpointsman.key
chmod 0600 /cockroach-certs/roach-client/client.jpointsman.key

rm /cockroach-certs/vault_response.json