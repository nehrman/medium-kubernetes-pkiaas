provider "vault" {
}

provider "vault" {
  alias     = "namespace"
  namespace = var.vault_namespace
}

