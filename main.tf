
provider "aws" {
  region = "us-east-1" # Replace with your desired AWS region
}
terraform {
  backend "s3" {
    bucket         = "janani-upgrad-campus"  # The same bucket name you used in the previous step
    key            = "terraform.tfstate"        # The state file name (can be any name you prefer)
    region         = "us-east-1"                # Replace with the region you specified in the provider block
    encrypt        = true
  }
}

# Create the VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MyVPC"
  }
}

# Create the internet gateway (IGW)
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "MyIGW"
  }
}

# Create the NAT gateway (NAT-GW) in AZ-a
resource "aws_eip" "my_eip" {
  domain = "vpc" # Use straight quotes here
}

resource "aws_nat_gateway" "my_nat_gw" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.my_public_subnet_a.id
  tags = {
    Name = "MyNATGW"
  }
}

# Create the public subnets in AZ-a and AZ-b
resource "aws_subnet" "my_public_subnet_a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Replace with your desired availability zone
  map_public_ip_on_launch = true
  tags = {
    Name                = "MyPublicSubnetA"
    "kubernetes.io/role/elb" = "1"  # EKS subnet tagging requirement
  }
}

resource "aws_subnet" "my_public_subnet_b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"  # Replace with your desired availability zone
  map_public_ip_on_launch = true
  tags = {
Name                = "MyPublicSubnetB"
    "kubernetes.io/role/elb" = "1"  # EKS subnet tagging requirement
  }
}

# Create the private subnets in AZ-a and AZ-b
resource "aws_subnet" "my_private_subnet_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"  # Replace with your desired availability zone
  tags = {
    Name                = "MyPrivateSubnetA"
    "kubernetes.io/role/internal-elb" = "1"  # EKS subnet tagging requirement
  }
}

resource "aws_subnet" "my_private_subnet_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"  # Replace with your desired availability zone
  tags = {
    Name                = "MyPrivateSubnetB"
    "kubernetes.io/role/internal-elb" = "1"  # EKS subnet tagging requirement
  }
}

# Create the route tables for the public and private subnets
resource "aws_route_table" "my_public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "MyPublicRouteTable"
  }
}

resource "aws_route_table" "my_private_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "MyPrivateRouteTable"
  }
}

# Create routes for the public route table
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.my_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

# Create routes for the private route table
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.my_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gw.id
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public_subnet_association_a" {
  subnet_id      = aws_subnet.my_public_subnet_a.id
  route_table_id = aws_route_table.my_public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association_b" {
  subnet_id      = aws_subnet.my_public_subnet_b.id
  route_table_id = aws_route_table.my_public_route_table.id
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_subnet_association_a" {
  subnet_id      = aws_subnet.my_private_subnet_a.id
  route_table_id = aws_route_table.my_private_route_table.id
}

resource "aws_route_table_association" "private_subnet_association_b" {
  subnet_id      = aws_subnet.my_private_subnet_b.id
  route_table_id = aws_route_table.my_private_route_table.id
}
