resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = var.cert_manager_namespace

    labels = {
      name = var.cert_manager_namespace
    }
  }
}

/*resource "null_resource" "cert-manager-crds" {
  depends_on = ["kubernetes_namespace.cert-manager"]

  provisioner "local-exec" "cert-manager" {
    command = "kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.crds.yaml"
  }
}
*/

resource "helm_release" "cert-manager" {
  #  depends_on = ["null_resource.cert-manager-crds"]
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert-manager.metadata[0].name
  version    = "1.0.4"

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "local_file" "vault-issuer" {
  content = templatefile("${path.module}/templates/vault-issuer.tpl", {
    vault_k8s_backend_path = vault_auth_backend.minikube.path
    vault_k8s_role         = vault_kubernetes_auth_backend_role.cert-manager.role_name
    namespace              = var.fruits_namespace
    vault_address          = var.vault_addr
    secret_name            = kubernetes_service_account.cert-manager-sa.default_secret_name
  })
  filename = "${path.module}/files/vault-issuer.yaml"
}

resource "null_resource" "vault-issuer" {
  depends_on = [
    helm_release.cert-manager,
    local_file.vault-issuer,
  ]

  provisioner "local-exec" {
    command = "kubectl apply --insecure-skip-tls-verify -f ./files/vault-issuer.yaml"
  }
}

resource "local_file" "fruits-certificate" {
  content = templatefile("${path.module}/templates/fruits-certificate.tpl", {
    name       = var.name
    namespace  = var.fruits_namespace
    commonname = var.commonname
    secretname = var.secretname
    dns_names  = var.dns_names
  })
  filename = "${path.module}/files/fruits-certificate.yaml"
}

resource "null_resource" "fruits-certificate" {
  depends_on = [
    helm_release.cert-manager,
    local_file.fruits-certificate,
  ]

  provisioner "local-exec" {
    command = "kubectl apply --insecure-skip-tls-verify -f ./files/fruits-certificate.yaml"
  }
}

