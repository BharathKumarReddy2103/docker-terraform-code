# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get the first subnet from the list
data "aws_subnet" "default" {
  id = data.aws_subnets.default.ids[0]
}

resource "aws_instance" "docker" {
  ami           = local.ami_id
  #instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow_all_docker.id]
  instance_type = "t3.medium"
  subnet_id     = data.aws_subnet.default.id  
  # need more for terraform
  root_block_device {
    volume_size = 50
    volume_type = "gp3" # or "gp2", depending on your preference
  }
  user_data = file("docker.sh")
  #iam_instance_profile = "TerraformAdmin"
  tags = {
     Name = "${var.project}-${var.environment}-docker"
  }
}

resource "aws_security_group" "allow_all_docker" {
    name        = "allow_all_docker"
    description = "allow all traffic"

    ingress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    lifecycle {
      create_before_destroy = true
    }

    tags = {
        Name = "allow-all-docker"
    }
}