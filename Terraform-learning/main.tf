provider "aws" {
    region = "us-east-2"
}


variable "cidr_blocks" {
  description = "description"
  type = list(object({
      cidr_block = string
      name = string
  }))
}


resource "aws_vpc" "dev-vpc" {
    cidr_block = var.cidr_blocks[0].cidr_block
    tags = {
        Name: var.cidr_blocks[0].name
    }
}

resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = var.cidr_blocks[1].cidr_block
    availability_zone = "us-east-2a"
    tags = {
        Name: var.cidr_blocks[1].name
    }
}

data "aws_vpc" "existing-vpc" {
    default = true
}

resource "aws_subnet" "dev-subnet-2" {
    vpc_id = data.aws_vpc.existing-vpc.id
    cidr_block = var.cidr_blocks[2].cidr_block
    availability_zone = "us-east-2a"
    tags = {
        Name: var.cidr_blocks[2].name
    }
}

/*
data "aws_vpc" "created_vpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "dev-subnet-3" {
    vpc_id = data.aws_vpc.created_vpc.id
    cidr_block = "10.0.20.0/24"
    availability_zone = "us-east-2a"
    tags = {
        Name: "subnet-dev-3"
    }
}
*/


output "dev-vpc-id" {
    value = aws_vpc.dev-vpc.id
}

output "dev-subnet1-id" {
    value = aws_subnet.dev-subnet-1.id
}

output "dev-subnet2-id" {
    value = aws_subnet.dev-subnet-2.id
}