terraform {
 required_providers {
   aws = {
     source = "hashicorp/aws"
     version = "5.83.1"
   }
 }
 required_version = ">= 1.1.5"
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}
#1 vpc
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name_prefix}_vpc"
  }
}
#2 igw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.name_prefix}_igw"
  }
}
#3 public subnet
resource "aws_subnet" "public_subnet" {
  count = var.subnet_count.public
  vpc_id = aws_vpc.main.id 
  cidr_block = var.public_subnet_cidr[count.index] 
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.name_prefix}_public_subnet_${count.index}"
  }
}
#private subnet
resource "aws_subnet" "private_subnet" {
  count = var.subnet_count.private
  vpc_id = aws_vpc.main.id 
  cidr_block = var.private_subnet_cidr[count.index] 
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.name_prefix}_private_subnet_${count.index}"
  }
}
#4 public rtb
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  count = var.subnet_count.public
  route_table_id = aws_route_table.public_rt.id
  subnet_id = aws_subnet.public_subnet[count.index].id
}

#private rtb
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "private" {
  count = var.subnet_count.private
  route_table_id = aws_route_table.private_rt.id
  subnet_id = aws_subnet.private_subnet[count.index].id
}
#5 web_app security grp
resource "aws_security_group" "web_app_sg" {
  name = "${var.name_prefix}_web_app_sg"
  description = "security group for web servers"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "allow SSH from my computer"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = [local.my_public_ip] #fetching my_ip code
   
  }
  ingress {
    description = "allow all traffic thro HTTP"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name_prefix}web_app_sg"
  }
}
#ec2 security grp
resource "aws_security_group" "ec2_sg" {
  name = "${var.name_prefix}_ec2_sg"
  description = "security group for ec2"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "allow traffic from only web_sg"
    from_port = "443"
    to_port   = "443"
    protocol  = "tcp"
    security_groups = [aws_security_group.web_app_sg.id]
  }
  tags = {
    Name = "${var.name_prefix}_ec2_sg"
  }
}

#create Linux ami
data "aws_ami" "amazon_linux" {
  most_recent = "true"
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
#create EC2 roger_web
resource "aws_instance" "ec2_web" {
  count = var.settings.web_app.count
  ami = data.aws_ami.amazon_linux.id
  instance_type = var.settings.web_app.instance_type
  subnet_id = aws_subnet.public_subnet[count.index].id
  key_name = var.aws_key_pair
  vpc_security_group_ids = [aws_security_group.web_app_sg.id]
  tags ={
    Name = "${var.name_prefix}_web_${count.index}"
  }
}
#create elastic IP for EC2
resource "aws_eip" "ec2_web_eip" {
  count = var.settings.web_app.count
  instance = aws_instance.ec2_web[count.index].id
  
  tags = {
    Name = "${var.name_prefix}_web_eip_${count.index}"
  }
}