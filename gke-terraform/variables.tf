variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}

variable "gke_region" {  
  default     = "us-central1"
  description = "GKE region"
}

variable "kubernetes_version" {  
  default     = "1.30"
  description = "Kubernetes version"  
}
