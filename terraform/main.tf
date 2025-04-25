###############################################################################
# AWS Jenkins Master Infrastructure Configuration
###############################################################################

#------------------------------------------------------------------------------
# Security Group for Jenkins Master
#------------------------------------------------------------------------------
resource "aws_security_group" "JenkinsMaster" {
  name        = "JenkinsMaster"
  description = "Security group for Jenkins Master instance"
  vpc_id      = var.vpc_id

  # Jenkins Web Interface Access
  ingress {
    description = "Allow Jenkins web interface access from all IPs"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH Access
  ingress {
    description = "Allow SSH access from all IPs (WARNING: Consider restricting in production)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Internet Access
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "JenkinsMaster Instance"
  }
}

#------------------------------------------------------------------------------
# AMI Configuration
#------------------------------------------------------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*al2023-ami-2023.6.*-kernel-6.1-x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["amazon"]
}

#------------------------------------------------------------------------------
# IAM Role Configuration
#------------------------------------------------------------------------------
resource "aws_iam_role" "StartRole" {
  name = "StartRole"

  # Role trust relationship policy
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Instance profile for the IAM role
resource "aws_iam_instance_profile" "StartRole" {
  name = "StartRole"
  role = aws_iam_role.StartRole.name
}

# IAM role policy 
resource "aws_iam_role_policy" "BasePolicy" {
  name = "BasePolicy"
  role = aws_iam_role.StartRole.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
}

#------------------------------------------------------------------------------
# Jenkins Master EC2 Instance
#------------------------------------------------------------------------------
resource "aws_instance" "JenkinsMaster" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t2.xlarge"
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.StartRole.name
  security_groups      = [aws_security_group.JenkinsMaster.name]
  user_data           = file("../install_jenkins.sh")

  tags = {
    Name        = "Jenkins"
    Environment = "Production"
  }
}