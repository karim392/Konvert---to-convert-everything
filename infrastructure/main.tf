#initiate VPC

resource "aws_vpc" "Konvert_VPC" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}



#initiate Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.Konvert_VPC.id
  cidr_block              = var.public_subnet_cidr[count.index]
  count                   = length(var.public_subnet_cidr)
  map_public_ip_on_launch = true
  tags = {
    Name = "APP-Konvert-public-subnet-${count.index + 1}"
  }
}

#initiate private Subnet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.Konvert_VPC.id
  cidr_block = var.private_subnet_cidr[count.index]
  count      = length(var.private_subnet_cidr)
  tags = {
    Name = "DB-Konvert-private-subnet-${count.index + 1}"
  }
}


#initiate Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.Konvert_VPC.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}


#initiate load balancer subnets
resource "aws_lb" "Konvert_ALB" {
  subnets            = aws_subnet.public.*.id
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  tags = {
    Name = "${var.project_name}-alb"
  }
}

#Allow HTTP and HTTPS traffic
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.Konvert_VPC.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Grap the AMI ID
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]

}

#Create EC2 in the public subnet

resource "aws_instance" "app_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = element(aws_subnet.public.*.id, count.index)
  count                       = 2
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-EC2-${count.index + 1}"
  }
}

#Create Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2_sg"
  description = "Allow HTTP traffic to EC2 instances"
  vpc_id      = aws_vpc.Konvert_VPC.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#Create DB Subnet Group
resource "aws_db_subnet_group" "konvert_db_subnet" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private.*.id
}

#Create RDS in the private subnet
resource "aws_db_instance" "konvert_db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = "${var.project_name}_db"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.konvert_db_subnet.id


  tags = {
    Name = "${var.project_name}-RDS"
  }
}

#create Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds_sg"
  description = "Allow traffic to RDS instances"
  vpc_id      = aws_vpc.Konvert_VPC.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}



#Create replica for RDS
resource "aws_db_instance" "konvert_db_replica" {
  replicate_source_db  = aws_db_instance.konvert_db.id
  instance_class       = "db.t3.micro"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true

  tags = {
    Name = "${var.project_name}-RDS-Replica"
  }
}

# WAF Web ACL
resource "aws_wafv2_web_acl" "konvert_waf" {
  name        = "${var.project_name}-waf"
  scope       = "REGIONAL"
  description = "WAF for Konvert application"
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf-metric"
    sampled_requests_enabled   = true
  }
}


# Route53 Hosted Zone
resource "aws_route53_zone" "konvert_zone" {
  name = "konvert.example.com"
}


#Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "konvert_waf_alb" {
  resource_arn = aws_lb.Konvert_ALB.arn
  web_acl_arn  = aws_wafv2_web_acl.konvert_waf.arn
}


