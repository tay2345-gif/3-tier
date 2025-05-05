provider "aws" {
  region = var.aws_region 
}

terraform {     #Backend
    cloud {
    organization = "the-best"
    workspaces {
      name = "3-tier"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.20.0.0/16"
}

resource "aws_subnet" "public_subnet_A" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.10.0/24"
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "public_subnet_B" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.20.0/24"
  availability_zone       = "us-east-1b"
  
}

resource "aws_subnet" "private_App_subnet_A" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.30.0/24"
  availability_zone       = "us-east-1c"
}

resource "aws_subnet" "private_App_subnet_B" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.40.0/24"
  availability_zone       = "us-east-1d"
}

resource "aws_subnet" "private_Data_subnet_A" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.20.50.0/24"
}

resource "aws_subnet" "private_Data_subnet_B" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.20.60.0/24"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "3-tier"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "3-tier Public Route Table"
  }
}

resource "aws_route_table_association" "public_subnet_A_assoc" {
  subnet_id      = aws_subnet.public_subnet_A.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_B_assoc" {
  subnet_id      = aws_subnet.public_subnet_B.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_instance" "Nginx-Webserver1" {
  ami                    = "ami-084568db4383264d4"  # Amazon Ubuntu AMI (Check latest AMI)
  count = 2
  instance_type          = "t2.micro"
  associate_public_ip_address = true
  subnet_id = [aws_subnet.public_subnet_A.id, aws_subnet.public_subnet_B.id]
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              sudo amazon-linux-extras install -y nginx1
              sudo systemctl start nginx
              sudo systemctl enable nginx
              echo "Hello from Nginx Server ${count.index + 1}" > /usr/share/nginx/html/index.html
              EOF
}


resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = 80
    to_port     = 80
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

