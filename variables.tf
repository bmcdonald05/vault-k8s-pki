### k8s ###
variable "k8s_host" {
  type        = string
  description = "Host must be a host string, a host:port pair, or a URL to the base of the Kubernetes API server."
  default     = ""
}

variable "k8s_ca_cert" {
  type        = string
  description = "PEM encoded CA cert for use by the TLS client used to talk with the Kubernetes API."
  default     = ""
}

variable "token_review_jwt" {
  type        = string
  description = "A service account JWT used to access the TokenReview API to validate other JWTs during login. If not set the JWT used for login will be used to access the API."
  default     = ""
}
