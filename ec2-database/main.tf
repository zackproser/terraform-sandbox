provider "aws" {
  region = "us-west-2"
}

#-----------------------------------------------------------------------------------------
# CREATE A VPC WITH 2 SUBNETS: 1 PUBLIC, 1 PRIVATE
#-----------------------------------------------------------------------------------------

# Create our main VPC, which will contain 2 subnets: 1 public (accessible from the internet )and 1 private
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
}

# Designate a 256 host subnet that will be publicly accessible from the internet 
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  # State that each new ec2 instance launched should automatically be assigned a public IP adress
  map_public_ip_on_launch = true
}

# Designate a 256 host subnet (for databases) that will not be reachable from the internet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

#-----------------------------------------------------------------------------------------
# CREATE AN INTERNET GATEWAY AND ROUTE TABLE ALLOWING THE PUBLIC SUBNET ACCESS TO THE INTERNET
#-----------------------------------------------------------------------------------------

# Create an internet gateway, which grants the public subnet access to the internet 
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Create a route sending traffic destined for any address through the internet gateway
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate our defined route table with our public subnet 
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

#-----------------------------------------------------------------------------------------
# CREATE SECURITY GROUPS CONTROLLING ACCESS TO AND FROM THE EC2 INSTANCE 
#-----------------------------------------------------------------------------------------

resource "aws_security_group" "allow_http" {
  name   = "allow_http"
  vpc_id = aws_vpc.main.id

  # Allow TCP traffic to port 80 only - from anywhere on the internet 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow the ec2 instance to go outbound to the public internet across any protocol and port 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Render the user data script that will be run on startup of the ec2 instance
data "template_file" "userdata" {
  template = "${file("${path.cwd}/data/userdata.tpl")}"
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  vpc_id = aws_vpc.main.id
  
  # Allow TCP traffic to port 22 only - from anywhere on the internet 
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#-----------------------------------------------------------------------------------------
# CREATE SSH KEY PAIR
#-----------------------------------------------------------------------------------------

# Generate local ssh key 
resource "tls_private_key" "key" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

# Create a key pair for use with the ec2 instance
resource "aws_key_pair" "generated_key" {
    key_name = "ssh-key"
    public_key = tls_private_key.key.public_key_openssh
}

# Intentionally output the ssh key so that we can use it to access the instance
# Once Terraform has applied your config successfully, the ssh_key output will be
# written to stdout so that you can see it and save the key: 
#
# First, save the key to your ssh directory 
#   
# terraform output ssh_key > ~/.ssh/ec2-database-test
# 
# Next, ensure the key is readable only by your user 
# 
# chmod 400 ~/.ssh/ec2-database-test
# 
# Finally, load the private key into your ssh-agent
# 
# ssh-add ~/.ssh/ec2-database-test
# 
output "ssh_key" {
    value = tls_private_key.key.private_key_pem
}

#-----------------------------------------------------------------------------------------
# CREATE EC2 INSTANCE 
#-----------------------------------------------------------------------------------------
resource "aws_instance" "helloworld" {
  # A ubuntu image in us-west-2
  ami           = "ami-e1906781"
  instance_type = "t2.micro"
  tags = {
    Name = "HelloWorld"
  }

  subnet_id       = aws_subnet.public.id
  # Add the security groups we created above to allow http and ssh traffic to the instance
  security_groups = [aws_security_group.allow_http.id, aws_security_group.allow_ssh.id]

  key_name = aws_key_pair.generated_key.key_name

  user_data = data.template_file.userdata.rendered
}

# Output the instance's IP address so that it's easier to SSH to it after running apply
output "instance_ip" {
    value = aws_instance.helloworld.public_ip
}

