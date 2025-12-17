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
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "APP-Konvert-public-subnet-${count.index + 1}"
  }
}

#initiate private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.Konvert_VPC.id
  cidr_block        = var.private_subnet_cidr[count.index]
  count             = length(var.private_subnet_cidr)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  tags = {
    Name = "DB-Konvert-private-subnet-${count.index + 1}"
  }
}


#initiate Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id     = aws_vpc.Konvert_VPC.id
  depends_on = [aws_vpc.Konvert_VPC]

  tags = {
    Name = "${var.project_name}-igw"
  }
}


#initiate Route Table for public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.Konvert_VPC.id
  tags = {
    Name = "${var.project_name}-public-route-table"
  }
}

#Create route to Internet Gateway
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

#Associate Route Table with public subnet
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.public_rt.id
  count          = length(aws_subnet.public.*.id)
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
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = element(aws_subnet.public.*.id, count.index)
  count                       = 2
  source_dest_check           = true
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name                    = var.SSH_key_name

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
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol  = "-1"
  }
}


#Create Application load balancer (ALB) subnets
resource "aws_lb" "Konvert_ALB" {
  subnets            = aws_subnet.public.*.id
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  tags = {
    Name = "${var.project_name}-alb"
  }
}

#ALB Target Group
resource "aws_lb_target_group" "alb_target_group" {
  name        = "${var.project_name}-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.Konvert_VPC.id
  target_type = "instance"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#Associate EC2 instances with ALB Target Group
resource "aws_lb_target_group_attachment" "alb_target_attachment" {
  count            = length(aws_instance.app_server.*.id)
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = element(aws_instance.app_server.*.id, count.index)
  port             = 80
}


#ALB Listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.Konvert_ALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create DB Subnet Group
resource "aws_db_subnet_group" "konvert_db_subnet" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private.*.id
}

#Create RDS in the private subnet
#resource "aws_db_instance" "konvert_db" {
#  identifier              = "${var.project_name}-primary-db"
#  allocated_storage       = 20
#  engine                  = "mysql"
#  backup_retention_period = 1
#  engine_version          = "8.0"
#  instance_class          = "db.t3.micro"
#  db_name                 = "${var.project_name}_db"
#  username                = var.db_username
#  password                = var.db_password
#  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
#  parameter_group_name    = "default.mysql8.0"
#  skip_final_snapshot     = true
#  db_subnet_group_name    = aws_db_subnet_group.konvert_db_subnet.id


#  tags = {
#    Name = "${var.project_name}-RDS"
#  }
#}


#Create replica for RDS
#resource "aws_db_instance" "konvert_db_replica" {
#  depends_on           = [aws_db_instance.konvert_db]
#  identifier           = "${var.project_name}-replica-db"
#  replicate_source_db  = aws_db_instance.konvert_db.identifier
#  instance_class       = "db.t3.micro"
#  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
#  parameter_group_name = "default.mysql8.0"
#  skip_final_snapshot  = true

#  tags = {
#    Name = "${var.project_name}-RDS-Replica"
#  }
#}

#Create Security Group for RDS
#resource "aws_security_group" "rds_sg" {
#  name        = "${var.project_name}-rds_sg"
#  description = "Allow traffic to RDS instances"
#  vpc_id      = aws_vpc.Konvert_VPC.id
#  ingress {
#    from_port       = 3306
#    to_port         = 3306
#    protocol        = "tcp"
#    security_groups = [aws_security_group.ec2_sg.id]
#  }

#  egress {
#    from_port = 0
#    to_port   = 0
#    protocol  = "-1"
#  }
#}


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
#resource "aws_route53_zone" "konvert_zone" {
#  name = "konvert.example.com"
#}


#Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "konvert_waf_alb" {
  resource_arn = aws_lb.Konvert_ALB.arn
  web_acl_arn  = aws_wafv2_web_acl.konvert_waf.arn
}


# Need the IP address of EC2 instances
output "ec2_public_ip_addresses" {
  description = "The public IPs of the EC2 instances"
  value       = aws_instance.app_server.*.public_ip
}


resource "null_resource" "ansible_provisioning" {
  # Trigger only when the instance is created or its IP changes
  triggers = {
    ec2_public_ip_address = join(" ", aws_instance.app_server.*.public_ip)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    working_dir = "/home/lenovo/DevOps/Konvert-web-to-convert/infrastructure/Ansible"

    command = <<-EOT
      set -e

      echo "Waiting for EC2 SSH to be ready..."

      # Wait for SSH on every EC2 instance
      for ip in ${join(" ", aws_instance.app_server.*.public_ip)}; do
        echo "Waiting for SSH on $ip ..."
        until nc -z -w5 $ip 22; do
          echo "SSH not ready on $ip yet... retrying in 5s"
          sleep 5
        done
        echo "SSH is ready on $ip"
      done


      echo "[webservers]" > temp_inventory

      # Loop through all instance public IPs
      for ip in ${join(" ", aws_instance.app_server.*.public_ip)}; do
        echo "$ip ansible_user=ubuntu ansible_ssh_private_key_file=/home/lenovo/Downloads/SSH-key.pem" >> temp_inventory
      done

      ansible-playbook -i temp_inventory playbook.yaml

      rm temp_inventory
      
    EOT
  }
}

