provider "aws" {
    region = "us-east-2"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block

    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone

    tags = {
      Name: "${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id

    tags = {
        "Name" = "${var.env_prefix}-igw"
    }
}

resource "aws_default_route_table" "dafault-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }

  tags = {
    Name = "default-rtb"
  }
}

resource "aws_route_table_association" "a" {
    subnet_id      = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}

resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id

    ingress{
        cidr_blocks = [ var.my_ip]
        from_port = 22
        protocol = "tcp"
        to_port = 22
        }

    ingress{
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 8080
        protocol = "tcp"
        to_port = 8080
        }

    egress {
      cidr_blocks = [ "0.0.0.0/0" ]
      from_port = 0
      protocol = "-1"
      to_port = 0
    } 

    tags = {
      "Name" = "${var.env_prefix}-default-sg"
    }
}

data "aws_ami" "latest_ubuntu" {
    most_recent = true
    owners = ["099720109477"]
    filter{
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20211129"]
        }

    filter{
        name = "virtualization-type"
        values = ["hvm"]
        }
  
}
output "ami-name" {
    value = data.aws_ami.latest_ubuntu.id
}

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key =  file(var.public_key_location)
  
}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest_ubuntu.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [ aws_default_security_group.default-sg.id ]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    user_data = file("entry-script.sh")

    tags = {
        Name: "${var.env_prefix}-server"
    }
}
