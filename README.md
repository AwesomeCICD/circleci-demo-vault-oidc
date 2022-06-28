# circleci-vault-oidc
This repo demonstrates how to use CircleCI OIDC tokens to authenticate with Vault.


### Prerequisites

1. Working [Hashicorp Vault](https://www.vaultproject.io/docs/install) cluster
2. The following information:
    - CircleCI Organization ID (can be found under CircleCI's Organization Settings)
    - Vault endpoint address  (e.g. `https://vault.example.internal:8200`)
    - Vault CA Cert (if you're using private TLS certs and want to check cert validity on the Vault endpoint)

3. A [Vault policy](https://www.vaultproject.io/docs/concepts/policies#creating-policies) with the permissions that you'd like to grant to a CircleCI project 

4. A Vault role using the above policy that will be assumed by CircleCI jobs.  Below is a sample role:

```sh
vault write auth/jwt/role/circleci-demo -<<EOF
{
  "allowed_redirect_uris":"http://localhost:8200/oidc/callback",
  "bound_audiences":"<your CircleCI Org ID>",
  "token_policies":["default", "circleci-nonprod"],
  "user_claim": "oidc.circleci.com/project-id",
  "role_type": "jwt",
  "ttl":"1h"
}
EOF
```


5. Hashicorp Vault [JWT auth plugin](https://www.vaultproject.io/docs/auth/jwt#jwt-verification) configured as shown below. You can add additional configuration to restrict access or map roles to individual projects, see the [Vault API]() docs for more details.

```sh
vault write auth/jwt/config -<<EOF
{
  "oidc_discovery_url": "https://oidc.circleci.com/org/<your CircleCI Org ID>",
  "bound_issuer":"https://oidc.circleci.com/org/<your CircleCI Org ID>",
  "default_role":"<your desired Vault role>"
}
EOF
```

6. A CircleCI context with the vars in [the table below](#required-environment-vars).



### Required Environment Vars

Add these to a context:

| Context var name | Example value | Notes |
|---|---|---|
|VAULT_ADDR|`https://vault.example.internal:8200`| |
|VAULT_CACERT_B64|N/A|Optional.  Base64-encoded Vault CA cert for verifying privately-issued TLS certs. |
|VAULT_CACERT|`~/vault-ca.pem`|Optional.  Path to Vault CA cert file. |
|VAULT_JWT_ROLE_NAME|`myvaultrole`|Vault role that the CircleCI job will assume.|



### Usage 

See this repo's `.circleci/config.yml` to understand how Vault authentication works in this example.  There are four commands:

- **install-vault** - installs Vault according to the directions in Hashicorp's docs
- **install-vault-auth-prereqs-alpine** - installs necessary packages on to Hashicorp's Vault docker image (Alpine Linux)
- **vault-token-generate** - generates a client token for the Vault role specified in VAULT_JWT_ROLE_NAME and saves it to a workspace
- **vault-token-restore** - restores the Vault token for use in later jobs in the same pipeline

Here's a config.yml snippet showing how these commands could be used:

```hcl
jobs:
  generate-vault-token:
    docker: 
      - image:  hashicorp/vault:1.11
    steps:
      - install-vault-auth-prereqs-alpine
      - vault-token-generate

  test-vault-token:
    docker: 
      - image:  hashicorp/vault:1.11
    steps:
      - install-vault-auth-prereqs-alpine
      - vault-token-restore
      - run:
          name: Authenticate with Vault and read/write a secret
          command: |
              echo "Writing and reading a secret..."
              vault write cubbyhole/my-secret my-value=s3cr3t
              vault read cubbyhole/my-secret
```