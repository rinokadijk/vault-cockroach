## HashiCorp Vault single instance and Cockroach DB 3-node cluster with Mutual TLS encryption

This example is used as part of this [blog post](https://rinokadijk.github.io/vault-cockroach/). 
This setup is NOT PRODUCTION READY! 

It demonstrates how to use the Vault api to issue certificates for a secure CockroachDB cluster.
From a CockroachDB perspective the in-transit encryption between CockroachDB nodes and SQL clients can be considered secure. However, the Vault instance is not configured in a secure way (see production considerations).

### Start the vault and cockroach db cluster

Make sure you have no running process which binds on port 8200, 8080 or 26257

First, build the vault-init-client and go-client:

```bash
docker-compose build
```

Next, start the containers:

```bash
docker-compose up
```

### Open CockraochDB UI

USERNAME: jpointsman 
 
PASSWORD Q7gc8rEdS

By default CockroachDB will use the node certificate as the server certificate for the dashboard (you can [change](https://www.cockroachlabs.com/docs/stable/create-security-certificates-custom-ca.html#accessing-the-admin-ui-for-a-secure-cluster) this behaviour). You will be prompted by your browser because server certificate issued by HashiCorp Vault for the dasboard is not trusted by your browser. If you accept this warning and login you should see a 3-node database cluster without insecure warnings.

```bash
open https://localhost:8080
```

### Open Vault UI

TOKEN: on disk in ./vault-token/root.token

```bash
open http://localhost:8200
```

### Use the client certificate for user jpointsman to show databases 

Don't stop the docker-compose command and run the following command in a separate terminal:

```bash
docker-compose run roach-client sql --user=jpointsman --execute="show databases;"
```

Or use the go-client to connect to the database with a client certificate in a separate terminal:

```bash
docker-compose run go-client
```

### Renew certificate

To renew all the certificates run the following command in a separate terminal:

```bash
docker-compose up -d vault-init-client
```

To reload the certificates without downtime run the following command:

```bash
docker-compose kill -s SIGHUP roach1 roach2 roach3
```

Check the certificate dates with the following command:

```bash
echo | openssl s_client -connect localhost:26257 2>/dev/null | openssl x509 -noout -dates
```

### Stop all docker instances

You can stop all the docker containers:

```bash
docker-compose kill
````

### Container Overview

#### vault

The official HashiCorp Vault Docker container running the Vault server on port 8200 with TLS disabled. The CA data, Intermediate CA data and all issued certificates are stored in this instance.  
Vault is configured with the UI enabled and a filesystem storage backend. The config is stored in the /vault-config volume mapping. 
The data and logs are available in the /vault-data volume mapping.

#### vault-init-client

A custom image based on the official HashiCorp Vault Docker container with jq and curl installed to simplify the extraction of certificates from vault API responses. This instance is responsible for using the Vault client to initialize and unseal the Vault server. Once it is unsealed it uses the root token to generate a CA, Intermediate CA and Digital Certificates for roach1, roach2, roach3 and roach-client. It shares the certificates with the other images through a shared Docker volume.

#### roach1

Standard CockroachDB Docker container without the join argument to automatically bootstrap the cluster. This node exposes the dashboard and sql server on port 8080 and 26257. Certificates are read from the /cockroach-data/roach1 volume mapping.

#### roach2

Standard CockroachDB Docker container with the join argument to automatically join the other nodes in the cluster. No ports are exposed to prevent a clash on the host. Certificates are read from the /cockroach-data/roach2 volume mapping.

#### roach3

Standard CockroachDB Docker container with the join argument to automatically join the other nodes in the cluster. No ports are exposed to prevent a clash on the host. Certificates are read from the /cockroach-data/roach3 volume mapping.

#### roach-client

Standard CockroachDB Docker container. Uses the CockroachDB client with the root account to create a Dashboard UI user. Certificates are read from the /cockroach-data/roach-client volume mapping.

#### go-client

Uses the golang sql library with the jpointsman account show the databases for this user. Certificates are read from the /cockroach-data/roach-client volume mapping.

### CockroachDB considerations
For a production-ready setup you should take at least the following into consideration:

- Don't start the first node without a --join option. On reboot this node might go transition to a single node cluster.
- Consider discovering your nodes in the cluster with a service discovery tool like [Consul](https://github.com/hashicorp/consul-template) instead of explicitly specifying the --join on all nodes  
- Expose ports 26257 and 8080 on all cockroach nodes and use a loadbalancer 

### Vault considerations
For a production-ready setup you should take at least the following into consideration:

- Don't use the tls_disable property for accessing the vault in production.
- Don't init the vault with -key-shares=1 -key-threshold=1 unless you are considering [auto-unseal](https://learn.hashicorp.com/vault/operations/ops-autounseal-aws-kms)
- Don't run dev server in production
- You must store your unseal and root token in a safe place
- You should not use the root token to generate certificates. Instead create a role and [policy](https://www.vaultproject.io/docs/concepts/policies.html)
- You should run vault in [HA mode](https://learn.hashicorp.com/vault/operations/ops-vault-ha-consul) (with consul)
- You should backup your vault
- You should make a plan for rotating your intermediate CA
- You should make a plan and monitor and [alert](https://github.com/cockroachdb/cockroach/blob/ca8fa726de54a0feea9f33ad000e883a4168ef39/monitoring/rules/alerts.rules.yml#L91) for CockroachDB expiring certificates
- You should revoke certificates that are not used anymore
- Consider using an existing CA to sign your intermediate CA instead of generating one with Vault
- Consider an extra layer of defense for the root and node certificates