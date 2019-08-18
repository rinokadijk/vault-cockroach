## HashiCorp Vault single instance and Cockroach DB secure 3-node cluster

This setup is NOT PRODUCTION READY! 

It demonstrates how to use the Vault api to issue certificates for a secure CockroachDB cluster.
From a CockroachDB perspective the in-transit encryption between cockroach nodes can be considered secure. However, the Vault instance is not configured in a secure way (see production considerations).

To start the vault and cockroach db cluster:

```bash
docker-compose build
docker-compose up
````

### Open CockraochDB UI

USERNAME: jpointsman 
 
PASSWORD Q7gc8rEdS

By default CockroachDB will use the node certificate as the server certificate for the dashboard (you can [change](https://www.cockroachlabs.com/docs/stable/create-security-certificates-custom-ca.html#accessing-the-admin-ui-for-a-secure-cluster) this behaviour). You will be prompted by your browser because server certificate issued by HashiCorp Vault for the dasboard is not trusted by your browser. If you accept this warning and login you should see a 3-node database cluster without insecude warnings.

```bash
open https://localhost:8080
````

### Open Vault UI

TOKEN: on disk in ./vault-token/root.token

```bash
open https://localhost:8200
````

### Stop all docker instances

You can stop all the docker containers:

```bash
docker-compose kill
````

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
- You should make a plan and monitor and [alert](https://github.com/cockroachdb/cockroach/blob/ca8fa726de54a0feea9f33ad000e883a4168ef39/monitoring/rules/alerts.rules.yml#L91) for cockroachdb expiring certificates
- You should revoke certificates that are not used anymore
- Consider using an existing CA to sign your intermediate CA instead of generating one with Vault