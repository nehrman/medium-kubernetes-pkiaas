## Configuring K8s AUth Method on Vault

resource "kubernetes_service_account" "vault-sa" {
  metadata {
    name      = "vault-sa"
    namespace = "${var.default_namespace}"
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "vault-sa" {
  metadata {
    name = "role-tokenreview-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.vault-sa.metadata.0.name}"
    namespace = "${var.default_namespace}"
  }
}

resource "vault_auth_backend" "minikube" {
  type = "kubernetes"
  path = "${var.vault_k8s_bck_path}"
}

resource "local_file" "minikube_auth" {
 content  = "${data.template_file.minikube_auth.rendered}"
   filename = "${path.module}/files/minikube_auth.sh"
}

resource "null_resource" "minikube_auth_backend" {
  depends_on = ["local_file.minikube_auth", "vault_auth_backend.minikube", "kubernetes_service_account.vault-sa"]

  provisioner "local-exec" "K8s_auth_backend" {
    command = "${path.module}/files/minikube_auth.sh"
   }
}

resource "kubernetes_service_account" "cert-manager-sa" {
  metadata {
    name      = "cert-manager-sa"
    namespace = "${var.fruits_namespace}"
  }

  automount_service_account_token = true
}

resource "vault_kubernetes_auth_backend_role" "cert-manager" {
  backend                          = "${vault_auth_backend.minikube.path}"
  role_name                        = "fruits-catalog"
  bound_service_account_names      = ["${kubernetes_service_account.cert-manager-sa.metadata.0.name}"]
  bound_service_account_namespaces = ["${var.fruits_namespace}"]
  policies                         = ["${vault_policy.fruits-catalog-certs.name}"]
  ttl                              = 86400
}

## Configuring PKI resources on Vault

resource "vault_pki_secret_backend" "pki" {
  path                  = "pki"
  max_lease_ttl_seconds = "315360000"
}

resource "vault_pki_secret_backend_root_cert" "pki" {
  depends_on = ["vault_pki_secret_backend.pki"]

  backend            = "${vault_pki_secret_backend.pki.path}"
  type               = "exported"
  format             = "pem_bundle"
  private_key_format = "der"
  key_type           = "rsa"
  key_bits           = 2048
  common_name        = "testlab.local"
  ttl                = "315360000"
}

resource "vault_pki_secret_backend" "pki_int" {
  path                  = "pki_int"
  max_lease_ttl_seconds = "157680000"
}

resource "vault_pki_secret_backend_intermediate_cert_request" "pki_int" {
  depends_on = ["vault_pki_secret_backend.pki_int"]

  backend     = "${vault_pki_secret_backend.pki_int.path}"
  type        = "exported"
  common_name = "testlab.local"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "pki" {
  depends_on = ["vault_pki_secret_backend_intermediate_cert_request.pki_int"]

  backend = "${vault_pki_secret_backend.pki.path}"

  csr         = "${vault_pki_secret_backend_intermediate_cert_request.pki_int.csr}"
  common_name = "testlab.local"
  ttl         = "157680000"
  format      = "pem_bundle"
}

resource "vault_pki_secret_backend_intermediate_set_signed" "pki_int" {
  backend = "${vault_pki_secret_backend.pki_int.path}"

  certificate = "${vault_pki_secret_backend_root_sign_intermediate.pki.certificate}"
}

resource "vault_pki_secret_backend_role" "fruits-catalog" {
  backend        = "${vault_pki_secret_backend.pki_int.path}"
  name           = "fruits-catalog"
  ttl            = 86400
  allow_any_name = "true"
  allow_subdomains = "true"
  generate_lease = "true"
}

resource "vault_pki_secret_backend_config_urls" "config_urls_root" {
  backend                 = "${vault_pki_secret_backend.pki.path}"
  issuing_certificates    = ["http://${var.vault_addr}/v1/pki/ca"]
  crl_distribution_points = ["http://${var.vault_addr}/v1/pki/crl"]
}

resource "vault_pki_secret_backend_config_urls" "config_urls_int" {
  backend                 = "${vault_pki_secret_backend.pki_int.path}"
  issuing_certificates    = ["http://${var.vault_addr}/v1/pki_int/ca"]
  crl_distribution_points = ["http://${var.vault_addr}/v1/pki_int/crl"]
}

resource "vault_policy" "fruits-catalog-certs" {
  name = "fruits-catalog-certs"

  policy = <<EOT
path "pki_int/sign/fruits-catalog" {
  capabilities = ["read", "update", "list", "delete"]
}

path "pki_int/issue/fruits-catalog" {
  capabilities = ["read", "update", "list", "delete"]
}
EOT
}



