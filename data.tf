data "helm_repository" "jetstack" {
  name = "jetstack"
  url  = "https://charts.jetstack.io"
}

// data "helm_repository" "fabric8" {
//   name = "fabric8"
//   url  = "https://fabric8.io/helm"
// }

data "template_file" "minikube_auth" {
  template = "${file("${path.module}/templates/minikube_auth.tpl")}"

  vars {
    service_account  = "${kubernetes_service_account.vault-sa.metadata.0.name}"
    k8s_backend_path = "minikube"
  }
}

data "template_file" "vault-issuer" {
  template = "${file("${path.module}/templates/vault-issuer.tpl")}"

  vars {
    vault_k8s_backend_path = "${vault_auth_backend.minikube.path}"
    vault_k8s_role = "${vault_kubernetes_auth_backend_role.cert-manager.role_name}"
    namespace      = "${var.fruits_namespace}"
    vault_address  = "${var.vault_addr}"
    secret_name    = "${kubernetes_service_account.cert-manager-sa.default_secret_name}"
  }
}

data "template_file" "fruits-certificate" {
  template = "${file("${path.module}/templates/fruits-certificate.tpl")}"

  vars {
    name       = "${var.name}"
    namespace  = "${var.fruits_namespace}"
    commonname = "${var.commonname}"
    secretname = "${var.secretname}"
    dns_names  = "${var.dns_names}"
  }
}
