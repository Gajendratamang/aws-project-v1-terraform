resource "aws_vpc" "project_v1" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "aws-project-v1-terraform-vpc"
    Environment = "Lab"
    Project     = "Project-V1"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.project_v1.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "aws-project-v1-public-subnet-a"
    Environment = "Lab"
    Project     = "Project-V1"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.project_v1.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "aws-project-v1-public-subnet-b"
    Environment = "Lab"
    Project     = "Project-V1"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.project_v1.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = "eu-west-2a"

  tags = {
    Name        = "aws-project-v1-private-subnet-a"
    Environment = "Lab"
    Project     = "Project-V1"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.project_v1.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = "eu-west-2b"

  tags = {
    Name        = "aws-project-v1-private-subnet-b"
    Environment = "Lab"
    Project     = "Project-V1"
  }
}

resource "aws_internet_gateway" "project_v1_igw" {
  vpc_id = aws_vpc.project_v1.id

  tags = {
    Name        = "aws-project-v1-igw"
    Environment = "Lab"
    Project     = "Project-V1"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.project_v1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_v1_igw.id
  }

  tags = {
    Name        = "aws-project-v1-public-rt"
    Environment = "Lab"
    Project     = "Project-V1"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.project_v1.id

  tags = {
    Name        = "aws-project-v1-private-rt"
    Environment = "Lab"
    Project     = "Project-V1"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}