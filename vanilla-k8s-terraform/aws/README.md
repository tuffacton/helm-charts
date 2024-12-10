# Vanilla K8S Simulated on AWS

This is meant to be a simple setup for deploying a Kubernetes cluster on AWS and then utilzing it to deploy Harness in a minimal configuration.

# Installation
Please review the `ec2.tf` and ensure you've swapped any necessary variables for your environment. This is configured to simply install on the AWS-provided public default VPC, but of course you can apply any private/subnet configurations as needed.

## Pre-Requisites
- AWS CLI
- Terraform
- Kubernetes
  - Kubectl
  - Helm
- OpenSSL

## Steps
1. You'll need to create keys that will be utilized for access to the EC2 instance e.g. generate an SSH key pair using the command `ssh-keygen -t rsa -b 2048 -f my-key` and follow the prompts to save it securely.
2. Make sure to set the appropriate permissions for your key using `chmod 400 my-key`.