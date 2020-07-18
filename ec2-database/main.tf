provider "aws" {
  region = "us-west-2"
}

#-----------------------------------------------------------------------------------------
# CREATE A VPC WITH 2 SUBNETS: 1 PUBLIC, 1 PRIVATE
#-----------------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

#-----------------------------------------------------------------------------------------
# CREATE AN INTERNET GATEWAY AND ROUTE TABLE ALLOWING THE PUBLIC SUBNET ACCESS TO THE INTERNET
#-----------------------------------------------------------------------------------------

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

#-----------------------------------------------------------------------------------------
# CREATE SECURITY GROUP ENABLING EC2 INSTANCE ACCESS TO AND FROM THE INTERNET
#-----------------------------------------------------------------------------------------

resource "aws_security_group" "allow_http" {
  name   = "allow_http"
  vpc_id = aws_vpc.main.id

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

resource "aws_instance" "helloworld" {
  ami           = "ami-49484e79"
  instance_type = "t2.micro"
  tags = {
    Name = "HelloWorld"
  }

  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.allow_http.id]
}

