resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "${var.cert_manager_namespace}"
    labels {
      name = "${var.cert_manager_namespace}"
    }
  }
}

resource "null_resource" "cert-manager-crds" {
  depends_on = ["kubernetes_namespace.cert-manager"]

  provisioner "local-exec" "cert-manager" {
    command = "kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.0/cert-manager.crds.yaml"
  }
}

resource "helm_release" "cert-manager" {
  depends_on = ["null_resource.cert-manager-crds"]
  name       = "cert-manager"
  repository = "${data.helm_repository.jetstack.metadata.0.name}"
  chart      = "cert-manager"
  namespace  = "${kubernetes_namespace.cert-manager.metadata.0.name}"
  version    = "0.14.0"
}

resource "local_file" "vault-issuer" {
  content  = "${data.template_file.vault-issuer.rendered}"
  filename = "${path.module}/files/vault-issuer.yaml"
}

resource "null_resource" "vault-issuer" {
  depends_on = ["helm_release.cert-manager", "local_file.vault-issuer"]

  provisioner "local-exec" "vault_issuer" {
    command = "kubectl apply -f ./files/vault-issuer.yaml"
  }
}

resource "local_file" "fruits-certificate" {
  content  = "${data.template_file.fruits-certificate.rendered}"
  filename = "${path.module}/files/fruits-certificate.yaml"
}

resource "null_resource" "fruits-certificate" {
  depends_on = ["helm_release.cert-manager", "local_file.fruits-certificate"]

  provisioner "local-exec" "fruits-certificate" {
    command = "kubectl apply -f ./files/fruits-certificate.yaml"
  }
}
