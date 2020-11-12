variable "vault_token" {
  description = "Token for connectiong to Vault"
  default     = ""
}

variable "vault_addr" {
  description = "Vault Address to connect to"
  default     = "192.168.94.141:8200"
}

variable "vault_namespace" {
  description = "Vault Namespace to use with Vault"
  default     = "test"
}

variable "default_namespace" {
  description = "Namespace where to deploy things on K8s"
  default     = "default"
}

variable "cert_manager_namespace" {
  description = "Namespace where to deploy things on K8s"
  default     = "cert-manager"
}

variable "fruits_namespace" {
  description = "Namespace where to deploy things on K8s"
  default     = "fruits-catalog"
}

variable "vault_k8s_bck_path" {
  description = "Namespace where to deploy things on K8s"
  default     = "minikube"
}

variable "name" {
  description = "Name of the certificate configuration"
  default     = "fruits-certificate"
}

variable "secretname" {
  description = "Name of the K8s secret"
  default     = "fruits-certificate"
}

variable "commonname" {
  description = "Common Name used for certificates"
  default     = "testlab.local"
}

variable "dns_names" {
  description = "Dns Names used for certificates"
  default     = "fruits"
}

variable "database_name" {
  description = "MongoDB Database name"
  default     = "sampledb"
}

variable "database_user" {
  description = "MongoDB Database username"
  default     = "userEVY"
}

