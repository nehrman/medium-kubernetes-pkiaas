resource "random_string" "mongodb-password" {
  length  = 8
  special = false
}

resource "random_string" "mongodb-adm-password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.fruits_namespace

    labels = {
      app = "fruits-catalog"
    }
  }

  data = {
    database-name           = var.database_name
    database-user           = var.database_user
    database-password       = random_string.mongodb-password.result
    database-admin-password = random_string.mongodb-adm-password.result
  }

  type = "opaque"
}

resource "kubernetes_service" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.fruits_namespace

    labels = {
      app       = "fruits-catalog"
      container = "mongodb"
    }
  }

  spec {
    selector = {
      app       = "fruits-catalog"
      container = "mongodb"
    }

    session_affinity = "None"

    port {
      port        = 27017
      target_port = 27017
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_persistent_volume_claim" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.fruits_namespace

    labels = {
      app       = "fruits-catalog"
      container = "mongodb"
    }
  }

  spec {
    resources {
      requests = {
        storage = "2Gi"
      }
    }

    access_modes = ["ReadWriteOnce"]
  }
}

resource "kubernetes_deployment" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.fruits_namespace

    labels = {
      app       = "fruits-catalog"
      container = "mongodb"
    }
  }

  spec {
    strategy {
      type = "Recreate"
    }

    replicas = 1

    selector {
      match_labels = {
        app              = "fruits-catalog"
        deploymentconfig = "mongodb"
        container        = "mongodb"
      }
    }

    template {
      metadata {
        labels = {
          app              = "fruits-catalog"
          deploymentconfig = "mongodb"
          container        = "mongodb"
        }
      }

      spec {
        container {
          name = "mongodb"

          image = "centos/mongodb-32-centos7:latest"

          port {
            container_port = 27017
            protocol       = "TCP"
          }

          readiness_probe {
            timeout_seconds       = 1
            initial_delay_seconds = 3

            exec {
              command = [
                "/bin/sh",
                "-i",
                "-c",
                "mongo 127.0.0.1:27017/$MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --eval=\"quit()\"",
              ]
            }
          }

          liveness_probe {
            tcp_socket {
              port = 27017
            }

            timeout_seconds       = 1
            initial_delay_seconds = 3
          }

          env {
            name = "MONGODB_USER"

            value_from {
              secret_key_ref {
                key  = "database-user"
                name = kubernetes_secret.mongodb.metadata[0].name
              }
            }
          }
          env {
            name = "MONGODB_PASSWORD"

            value_from {
              secret_key_ref {
                key  = "database-password"
                name = kubernetes_secret.mongodb.metadata[0].name
              }
            }
          }
          env {
            name = "MONGODB_ADMIN_PASSWORD"

            value_from {
              secret_key_ref {
                key  = "database-admin-password"
                name = kubernetes_secret.mongodb.metadata[0].name
              }
            }
          }
          env {
            name = "MONGODB_DATABASE"

            value_from {
              secret_key_ref {
                key  = "database-name"
                name = kubernetes_secret.mongodb.metadata[0].name
              }
            }
          }

          resources {
            limits = {
              memory = "512M"
            }
          }

          volume_mount {
            name       = "mongodb-data"
            mount_path = "/var/lib/mongodb/data"
          }

          image_pull_policy = "IfNotPresent"

          security_context {
            privileged = false
            capabilities {
            }
          }

          termination_message_path = "/dev/termination-log"
        }

        volume {
          name = "mongodb-data"

          persistent_volume_claim {
            claim_name = "mongodb"
          }
        }

        restart_policy = "Always"

        dns_policy = "ClusterFirst"
      }
    }
  }
}

