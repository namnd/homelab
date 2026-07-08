resource "helm_release" "cnpg_database" {
  name       = "cnpg"
  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cluster"
  version    = "0.7.0"

  create_namespace = true
  namespace        = "cnpg-database"

  set = [
    {
      name  = "type"
      value = "postgresql"
    },
    {
      name  = "cluster.instances"
      value = 3
    },
    {
      name  = "cluster.storage.size"
      value = "10Gi"
    },
    {
      name  = "cluster.storage.storageClass"
      value = "longhorn-cnpg"
    }
  ]
}
