variable "instance_type" {
    description = "The type of instance to use for the EC2 instance."  
    default     = "m5.4xlarge"
}

variable "instance_name" {
    description = "The name of the EC2 instance."
    type        = string
    default     = "smp-vanilla-k8s"
}

variable "region" {
    description = "The AWS region to deploy the resources."
    default     = "us-east-2"
}

variable "owner" {
    description = "tag for the owner of this particular ec2 instance"
    default     = "nicacton"
}

variable "pub_key_path" {
    description = "The path to the SSH key for accessing the EC2 instance."
    type        = string
    default     = "~/.ssh/id_rsa.pub"  
}

variable "private_key_path" {  
    description = "The path to the private SSH key for accessing the EC2 instance."
    type        = string
    default     = "~/.ssh/id_rsa"  
}