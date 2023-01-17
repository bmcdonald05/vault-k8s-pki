terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.12.0"
    }
  }
}

# It is strongly recommended to configure this provider through the following environment variables:
### export VAULT_ADDR="http://127.0.0.1:8200"
### export VAULT_TOKEN=<VAULT_TOKEN_HERE>
# This makes it easier for each user to use their own credentials/environment

provider "vault" {
  # Configuration options
  skip_tls_verify = true   #Only If TLS has not been setup; such as on a dev cluster
  namespace       = "Demo" #Only If using a Vault namespace
}
