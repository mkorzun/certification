terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state.snuffles765"
    key = "workspaces/stage/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-up-and-runninglocks"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "image_id" {
  default = "ami-04505e74c0741db8d"
}

resource "tls_private_key" "stage" {
 algorithm = "RSA"
 rsa_bits  = 4096
}

resource "aws_key_pair" "stage" {
 key_name   = "stage-ssh-key"
 public_key = tls_private_key.stage.public_key_openssh
}

resource "aws_security_group" "stage_group" {
  name        = "stage_group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    description = "tomcat access"
    from_port   = 0
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_instance" "stage_instance" {
  ami = "${var.image_id}"
  instance_type = "${var.instance_type}"
  key_name = aws_key_pair.stage.key_name
  vpc_security_group_ids = ["${aws_security_group.stage_group.id}"]
  tags = {
    Name = "stage"
  }
}

resource "local_file" "private_key" {
  sensitive_content = tls_private_key.stage.private_key_pem
  filename          = format("%s/%s/%s", abspath(path.root), ".ssh", "stage-ssh-key.pem")
  file_permission   = "0600"
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl",
    {
      stage_ip = aws_instance.stage_instance.public_ip
      ssh_keyfile = local_file.private_key.filename
    }
  )
   filename = format("%s/%s", abspath(path.root), "inventory.yaml")
}