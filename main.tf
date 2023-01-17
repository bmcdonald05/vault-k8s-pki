data "vault_policy_document" "pki-app1" {
  rule {
    path         = "${vault_mount.pki-short.path}/issue/app1"
    capabilities = ["create", "update"]
    description  = "allow issuing certificates"
  }
}

resource "vault_policy" "pki-app1" {
  name   = "pki-app1"
  policy = data.vault_policy_document.pki-app1.hcl
}

locals {
  default_3y_in_sec  = 94608000
  default_2y_in_sec  = 63072000
  default_1y_in_sec  = 31536000
  default_30d_in_sec = 2592000
  default_60d_in_sec = 5184000
  default_1hr_in_sec = 3600
}
#################################
############ K8s Items ##########
#################################
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "minikube"
}

resource "vault_kubernetes_auth_backend_config" "minikube" {
  backend = vault_auth_backend.kubernetes.path
  # disable_iss_validation = false #Work around as this option is deprecated but gets set to 'true' sometimes via older Vault provider versions
  kubernetes_host    = var.k8s_host
  kubernetes_ca_cert = var.k8s_ca_cert
  token_reviewer_jwt = var.token_review_jwt
}

resource "vault_kubernetes_auth_backend_role" "role1" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "role1"
  bound_service_account_names      = ["app-sa"]
  bound_service_account_namespaces = ["*"]
  token_ttl                        = 3600
  token_max_ttl                    = 28800
  token_policies                   = ["default", vault_policy.pki-app1.name]
}

#################################
########### PKI Root ############
#################################
resource "vault_mount" "pki-root" {
  path                      = "pki-root"
  type                      = "pki"
  description               = "root PKI mount"
  default_lease_ttl_seconds = local.default_2y_in_sec
  max_lease_ttl_seconds     = local.default_3y_in_sec
}

resource "vault_pki_secret_backend_root_cert" "root-ca" {
  backend              = vault_mount.pki-root.path
  type                 = "internal"
  common_name          = "mcdevops.dev"
  ttl                  = local.default_1y_in_sec
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = "DevOps"
  organization         = "McDonald-Devops"
}

resource "vault_pki_secret_backend_role" "root-role" {
  backend        = vault_mount.pki-root.path
  name           = "2023-servers"
  allow_any_name = true
}

#################################
########### PKI Short ###########
#################################
resource "vault_mount" "pki-short" {
  path                      = "pki-short"
  type                      = "pki"
  description               = "short PKI mount"
  default_lease_ttl_seconds = local.default_30d_in_sec
  max_lease_ttl_seconds     = local.default_60d_in_sec
}

resource "vault_pki_secret_backend_intermediate_cert_request" "short" {
  backend     = vault_mount.pki-short.path
  type        = "internal"
  common_name = "sandbox.mcdevops.dev"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "short" {
  backend      = vault_mount.pki-root.path
  csr          = vault_pki_secret_backend_intermediate_cert_request.short.csr
  common_name  = "sandbox.mcdevops.dev"
  ou           = "DevOps"
  organization = "McDonald-Devops"
  ttl          = local.default_1y_in_sec
}

resource "vault_pki_secret_backend_intermediate_set_signed" "short" {
  backend     = vault_mount.pki-short.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.short.certificate
}

resource "vault_pki_secret_backend_role" "app1" {
  backend            = vault_mount.pki-short.path
  name               = "app1"
  allow_localhost    = true
  allow_subdomains   = false
  allow_bare_domains = true
  allow_glob_domains = false
  allowed_domains    = ["app1.sandbox.mcdevops.dev"]
  server_flag        = true
  client_flag        = true
  code_signing_flag  = true
  ttl                = 180 #3mins
  max_ttl            = 300 #6mins
}
