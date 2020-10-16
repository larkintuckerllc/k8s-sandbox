locals {
  name = "bootstrapper"
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = local.name
  }
}

resource "kubernetes_service_account" "this" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "this" {
  metadata {
    name = local.name
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "this" {
  metadata {
    name = local.name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.this.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.name
    namespace = local.name
  }
}

resource "kubernetes_job" "this" {
  metadata {
    name = local.name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  spec {
    template {
      metadata {}
      spec {
        automount_service_account_token = true
        container {
          name    = "bootstrapper"
          image   = var.image
        }
        service_account_name            = kubernetes_service_account.this.metadata[0].name
        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        }
      }
    }
  }
}

resource "kubernetes_cron_job" "this" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  spec {
    schedule = "0 0,12 * * *"
    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            affinity {
              node_affinity {
                required_during_scheduling_ignored_during_execution {
                  node_selector_term {
                    match_expressions {
                      key      = "node-role.kubernetes.io/master"
                      operator = "Exists"
                    }
                  }
                }
              }
            }
            automount_service_account_token = true
            container {
              name    = "bootstrapper"
              image   = var.image
            }
            service_account_name            = kubernetes_service_account.this.metadata[0].name
            toleration {
              key      = "node-role.kubernetes.io/master"
              operator = "Exists"
              effect   = "NoSchedule"
            }
          }
        }
      }
    }
  }
}
