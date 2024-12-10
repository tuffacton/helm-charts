terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.50.0"
    }
  }
}

provider "aws" {
  # Change to the region you intend
  region     = var.region
  # Tags that will be applied to all resources in this configuration
  default_tags {
    tags = {
      owner = var.owner
      purpose = "smp_testing"
    }
  }
}


resource "aws_security_group" "aws_sg" {
  name = "smp testing security group"

  ingress {
    description = "SSH from the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "80 from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "443 from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "6443 from the internet for k8s"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  # Be sure to replace below with a public key paired to a private key you would like to utilize
  public_key = file("${var.pub_key_path}")
}

# Grabs the latest AMI in the region for Amazon Linux 2023
data "aws_ami" "amzn_linux_2023_latest" {
    most_recent = true
    owners = [ "amazon" ]
    filter {
      name = "name"
      values = [ "al2023-ami-2023*" ]
    }
    filter {
      name = "architecture"
      values = [ "x86_64" ]
    }
    filter {
      name = "root-device-type"
      values = [ "ebs" ]
    }
    filter {
      name = "virtualization-type"
      values = [ "hvm" ]
    }
}


resource "aws_instance" "aws_ins_web" {
  ami                         = "${data.aws_ami.amzn_linux_2023_latest.id}"
  # Smallest size possible to run Harness on just one cluster
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.aws_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer.key_name
  root_block_device {
    volume_size = 500
    volume_type = "gp3"
    delete_on_termination = true
  }
  tags = {
    Name = var.instance_name
  }

  # Install k3s
  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | sh -s - --tls-san ${self.public_ip}",
      "echo 'K3s installed successfully!'"
    ]

    connection {
      host        = self.public_ip
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      type        = "ssh"
    }
  }

  # Create a local kubeconfig for accessing the K3s cluster from your local machine
  provisioner "local-exec" {
    command = <<EOT
      ssh -o "StrictHostKeyChecking=no" -i ${var.private_key_path} ec2-user@${self.public_ip} "sudo cat /etc/rancher/k3s/k3s.yaml" > k3s.yaml
      sed -i ''-e 's/127.0.0.1/${self.public_ip}/g' k3s.yaml
      echo "Kubeconfig is set to $(pwd)/k3s.yaml"
      echo "Run export KUBECONFIG=$(pwd)/k3s.yaml to use the cluster"
    EOT
  }
}

output "instance_ip" {
  value = aws_instance.aws_ins_web.public_ip
}

output "connection_command" {
  value = "ssh -i ${var.private_key_path} -o StrictHostKeyChecking=no ec2-user@${aws_instance.aws_ins_web.public_ip}"
}
