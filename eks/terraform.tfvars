region = "us-east-1"

availability_zones = ["us-east-1a", "us-east-1b"]

namespace = "istio-practice"

stage = "test"

name = "eks"

kubernetes_version = "1.15"

oidc_provider_enabled = true

enabled_cluster_log_types = ["audit"]

cluster_log_retention_period = 7

instance_types = ["t3.small"]

desired_size = 3

max_size = 3

min_size = 3

disk_size = 20

kubernetes_labels = {}
