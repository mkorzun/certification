terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state.snuffles765"
    key = "workspaces/build/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-up-and-runninglocks"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "subnet_id" {
  default = "subnet-build"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "vpc_id" {
  default = "vpc-build"
}

variable "image_id" {
  default = "ami-04505e74c0741db8d"
}

resource "tls_private_key" "build" {
 algorithm = "RSA"
 rsa_bits  = 4096
}

resource "aws_key_pair" "build" {
 key_name   = "build-ssh-key"
 public_key = tls_private_key.build.public_key_openssh
}

resource "aws_security_group" "build_group" {
  name        = "build_group"
  vpc_id      = "${var.vpc_id}"


  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "build_instance" {
  ami = "${var.image_id}"
  instance_type = "${var.instance_type}"
  key_name = aws_key_pair.build.key_name
  vpc_security_group_ids = ["${aws_security_group.build_group.id}"]
  subnet_id = "${var.subnet_id}"
  tags = {
    Name = "build"
  }
}

resource "local_sensitive_file" "private_key" {
  sensitive_content = tls_private_key.build.private_key_pem
  filename          = format("%s/%s/%s", abspath(path.root), ".ssh", "build-ssh-key.pem")
  file_permission   = "0600"
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl",
    {
      build_ip = aws_instance.build_instance.public_ip
      ssh_keyfile = local_file.private_key.filename
    }
  )
   filename = format("%s/%s", abspath(path.root), "inventory.yaml")
}