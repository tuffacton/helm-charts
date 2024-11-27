# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region, can be either commercial (e.g. us-east-1) or Govcloud (e.g. us-gov-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_version" {
  description = "The Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.29"
}