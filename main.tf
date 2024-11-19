provider "aws" {
  region = "us-east-1" 
}

# Data source to get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to get all subnets in the default VPC
data "aws_subnet" "default_subnets" {
  count = 3 # Adjust this count based on the number of subnets you want to use
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Variable defining instance names and corresponding availability zones
variable "instance_names" {
  type = map(object({
    az = string
  }))
  default = {
    "ansible_master" = { az = "us-east-1a" }
    "ansible_node1"  = { az = "us-east-1b" }
    "ansible_node2"  = { az = "us-east-1c" }
  }
}

# Resource block to create EC2 instances
resource "aws_instance" "ansible_servers" {
  for_each = var.instance_names

  ami                  = "ami-0866a3c8686eaeeba" # Change to your desired AMI ID
  instance_type       = "t2.micro"
  availability_zone    = each.value.az

  # Assigning subnet ID based on availability zone
  subnet_id = data.aws_subnet.default_subnets[lookup(var.instance_names, each.key).az].id

  vpc_security_group_ids = [aws_security_group.my_sg.id]

  tags = {
    Name = each.key
    Role = "Ansible Server"
  }

  key_name = "Ansible" # Ensure your key name is correct
}

# Security Group for the EC2 instances
resource "aws_security_group" "my_sg" {
  name        = "ansible_sg"
  description = "Allow SSH and other necessary ports"

  ingress {
    from_port   = 22  # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change this to restrict access
  }

  ingress {
    from_port   = 80  # HTTP
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # You can add additional rules as necessary
}
