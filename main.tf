######################################################

# Phase 1

#1 VPC (your private cloud)
#1 Public subnet (for web layer)
#1 Private subnet (for app + DB layer)
#Internet Gateway (connects the public subnet to the internet)
#NAT Gateway + Elastic IP (lets private subnet reach the internet outbound only)
#Route tables to connect subnets to gateways

######################################################


# Provider
provider "aws" {
    region = "us-east-1"
}

# VPC
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"

    tags = {
        Name = "todo-vpc"
    }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"

    tags = {
        Name = "todo-public-subnet"
    }
}

# Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "us-east-1b"

    tags = {
        Name = "todo-private-subnet-1"
    }
}

# Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.5.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "todo-private-subnet-2"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "todo-igw"
    }
}

# Elastic IP
resource "aws_eip" "eip" {
    domain = "vpc"

    tags = {
        Name = "todo-eip"
    }
}

# NAT (Network Address Translation) Gateway
resource "aws_nat_gateway" "nat_gw" {
    allocation_id = aws_eip.eip.id
    subnet_id = aws_subnet.public_subnet.id

    tags = {
        Name = "todo-nat_gw"
    }

    depends_on = [aws_internet_gateway.igw]
}

# Public Route Table
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "todo-public-rt"
    }
}

# Public Route Table Association
resource "aws_route_table_association" "public_route_table_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}

# Private Route Table
resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat_gw.id
    }

    tags = {
        Name = "todo-private-rt"
    }
}

# Private Route Table Association
resource "aws_route_table_association" "public_private_table_association" {
    subnet_id = aws_subnet.private_subnet_1.id
    route_table_id = aws_route_table.private_route_table.id
}

######################################################

# Phase 2

#Web SG – allows:
#Inbound SSH (22) from your IP
#Inbound HTTP (80) from anywhere
#Outbound everything

#App SG – allows:
#Inbound port 8080 only from Web SG
#Outbound everything

#DB SG – allows:
#Inbound port 3306 only from App SG
#Outbound everything

######################################################

# Security Group (Web-SG)
resource "aws_security_group" "web_sg" {
    name = "todo-web-sg"
    description = "Allow SSH from my IP, HTTP from anywhere and any outbound request"
    vpc_id = aws_vpc.vpc.id

    tags = {
      Name = "todo-web-sg"
    }
}

# Inbound SSH from my IP
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
    security_group_id = aws_security_group.web_sg.id
    cidr_ipv4 = "X.X.X.X/32" # your ip please
    from_port = 22
    ip_protocol = "tcp"
    to_port = 22
}

# Inbound HTTP (port 80) from anywhere
resource "aws_vpc_security_group_ingress_rule" "allow_http_for_web_sg" {
    security_group_id = aws_security_group.web_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80
}

# Outbound all traffic (IPv4)
resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4_from_web_sg" {
    security_group_id = aws_security_group.web_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

# Security Group (App-SG)
resource "aws_security_group" "app_sg" {
    name = "todo-app-sg"
    description = "Allow port 8080 from Web SG and all outbound traffic"
    vpc_id = aws_vpc.vpc.id

    tags = {
      Name = "todo-app-sg"
    }
}

# Inbound HTTP (port 8080) from only web-sg
resource "aws_vpc_security_group_ingress_rule" "allow_http_for_app_sg" {
    security_group_id = aws_security_group.app_sg.id
    referenced_security_group_id = aws_security_group.web_sg.id
    from_port = 8080
    ip_protocol = "tcp"
    to_port = 8080
}

# Outbound all traffic (IPv4)
resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4_from_app_sg" {
    security_group_id = aws_security_group.app_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

# Security Group (RDS-SG)
resource "aws_security_group" "rds_sg" {
    name = "todo-rds-sg"
    description = "Allow port 3306 from App SG and all outbound traffic"
    vpc_id = aws_vpc.vpc.id

    tags = {
      Name = "todo-rds-sg"
    }
}

# Inbound HTTP (port 3306) from only app-sg
resource "aws_vpc_security_group_ingress_rule" "allow_http_for_rds_sg" {
    security_group_id = aws_security_group.rds_sg.id
    referenced_security_group_id = aws_security_group.app_sg.id
    from_port = 3306
    ip_protocol = "tcp"
    to_port = 3306
}

# Outbound all traffic (IPv4)
resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4_from_rds_sg" {
    security_group_id = aws_security_group.rds_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

######################################################

# Phase 3

#Web EC2 → in Public Subnet, Web SG
#App EC2 → in Private Subnet, App SG

######################################################

# Data source for latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Web EC2 in Public Subnet with Web SG
resource "aws_instance" "web_ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.web_sg.id]
  key_name                    = "terraform-user-key-pair"
  tags = {
    Name = "web-ec2"
  }
}

# App EC2 in Private Subnet with App SG
resource "aws_instance" "app_ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet_1.id
  security_groups             = [aws_security_group.app_sg.id]
  key_name                    = "terraform-user-key-pair"
  tags = {
    Name = "app-ec2"
  }
}

######################################################

# Phase 4

#DB Subnet Group (tells RDS which subnets to use → private ones)
#RDS Instance:
#Engine = PostgreSQL
#Class = db.t3.micro
#Storage = 20–30 GB
#Username + Password (variables)
#Security Group = DB SG
#Not publicly accessible

######################################################

# DB Subnet Group (for private subnets)
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  tags = {
    Name = "db-subnet-group"
  }
}

# RDS Instance (PostgreSQL)
resource "aws_db_instance" "db_instance" {
  engine               = "postgres"
  engine_version       = "16.4"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  max_allocated_storage = 30
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  publicly_accessible  = false
  skip_final_snapshot  = true
  tags = {
    Name = "db-instance"
  }
}

# Variables for username and password
variable "db_username" {
  description = "RDS database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
}
