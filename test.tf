terraform {
required_providers {
aws = {
source = "hashicorp/aws"
version = "~> 5.0"
}
}
}
#configure provider
provider "aws" {
region = "us-east-1"
access_key = $CREDS
secret_key = $CREDS
}
#Configuration for Network Setup
# Creating a VPC
resource "aws_vpc" "proj-vpc" {
cidr_block = "10.0.0.0/16"
}
# Create an Internet Gateway
resource "aws_internet_gateway" "proj-ig" {
vpc_id = aws_vpc.proj-vpc.id
tags = {
Name = "gateway1"
}
}
# Setting up the route table
resource "aws_route_table" "proj-rt" {
vpc_id = aws_vpc.proj-vpc.id
route {
# pointing to the internet
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.proj-ig.id
}
route {
ipv6_cidr_block = "::/0"
gateway_id = aws_internet_gateway.proj-ig.id
}
tags = {
Name = "rt1"
}
}
#Security Group Configuration
# Setting up the subnet
resource "aws_subnet" "proj-subnet" {
vpc_id = aws_vpc.proj-vpc.id
cidr_block = "10.0.1.0/24"
availability_zone = "us-east-1a"
tags = {
Name = "subnet1"
}
}
# Associating the subnet with the route table
resource "aws_route_table_association" "proj-rt-sub-assoc" {
subnet_id = aws_subnet.proj-subnet.id
route_table_id = aws_route_table.proj-rt.id
}
# Creating a Security Group
resource "aws_security_group" "proj-sg" {
name = "proj-sg"
description = "Enable web traffic for the project"
vpc_id = aws_vpc.proj-vpc.id
ingress {
description = "HTTPS traffic"
from_port = 443
to_port = 443
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
description = "HTTP traffic"
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
description = "SSH port"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
ipv6_cidr_blocks = ["::/0"]
}
tags = {
Name = "proj-sg1"
}
}
# Creating a new network interface
resource "aws_network_interface" "proj-ni" {
subnet_id = aws_subnet.proj-subnet.id
private_ips = ["10.0.1.10"]
security_groups = [aws_security_group.proj-sg.id]
}
# Attaching an elastic IP to the network interface
resource "aws_eip" "proj-eip" {
vpc = true
network_interface = aws_network_interface.proj-ni.id
associate_with_private_ip = "10.0.1.10"
}
# Creating an Ubuntu EC2 instance
resource "aws_instance" "proj-instance" {
ami = "ami-053b0d53c279acc90"
instance_type = "t2.micro"
availability_zone = "us-east-1a"
key_name = "ubuntu_pem"
network_interface {
device_index = 0
network_interface_id = aws_network_interface.proj-ni.id
}
user_data = <<-EOF
#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
EOF
tags = {
Name = "test-server"
}
}
