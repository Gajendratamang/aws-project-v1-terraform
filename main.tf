terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "aws-lab"
}

module "network" {
  source = "./modules/network"

  vpc_cidr              = var.vpc_cidr
  public_subnet_a_cidr  = var.public_subnet_a_cidr
  public_subnet_b_cidr  = var.public_subnet_b_cidr
  private_subnet_a_cidr = var.private_subnet_a_cidr
  private_subnet_b_cidr = var.private_subnet_b_cidr
}

resource "aws_security_group" "web_sg" {
  name        = "aws-project-v1-web-sg"
  description = "Allow web traffic and restricted SSH"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "SSH from home IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.10/32"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "aws-project-v1-web-sg"
    Environment = "Lab"
    Project     = "Project-V1"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "aws-project-v1-alb-sg"
  description = "Allow HTTP traffic to the Application Load Balancer"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "aws-project-v1-alb-sg"
    Environment = "Lab"
    Project     = "Project-V1"
    ManagedBy   = "Terraform"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "aws-project-v1-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name        = "aws-project-v1-web-tg"
    Environment = "Lab"
    Project     = "Project-V1"
    ManagedBy   = "Terraform"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_lb" "web_alb" {
  name               = "aws-project-v1-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]

  subnets = [
    module.network.public_subnet_a_id,
    module.network.public_subnet_b_id
  ]

  tags = {
    Name        = "aws-project-v1-alb"
    Environment = "Lab"
    Project     = "Project-V1"
    ManagedBy   = "Terraform"
  }
}

moved {
  from = aws_vpc.project_v1
  to   = module.network.aws_vpc.project_v1
}

moved {
  from = aws_subnet.public_a
  to   = module.network.aws_subnet.public_a
}

moved {
  from = aws_subnet.public_b
  to   = module.network.aws_subnet.public_b
}

moved {
  from = aws_subnet.private_a
  to   = module.network.aws_subnet.private_a
}

moved {
  from = aws_subnet.private_b
  to   = module.network.aws_subnet.private_b
}

moved {
  from = aws_internet_gateway.project_v1_igw
  to   = module.network.aws_internet_gateway.project_v1_igw
}

moved {
  from = aws_route_table.public_rt
  to   = module.network.aws_route_table.public_rt
}

moved {
  from = aws_route_table.private_rt
  to   = module.network.aws_route_table.private_rt
}

moved {
  from = aws_route_table_association.public_a
  to   = module.network.aws_route_table_association.public_a
}

moved {
  from = aws_route_table_association.public_b
  to   = module.network.aws_route_table_association.public_b
}

moved {
  from = aws_route_table_association.private_a
  to   = module.network.aws_route_table_association.private_a
}

moved {
  from = aws_route_table_association.private_b
  to   = module.network.aws_route_table_association.private_b
}

resource "aws_launch_template" "web_lt" {
  name_prefix   = "aws-project-v1-web-"
  image_id      = "ami-08fda247309883f97"
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<EOF
#!/bin/bash
dnf install -y httpd
systemctl enable httpd
systemctl start httpd

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

echo "<h1>AWS Project V1</h1><p>Auto Scaling Instance: $INSTANCE_ID</p><p>Availability Zone: $AZ</p>" > /var/www/html/index.html
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "aws-project-v1-asg-web"
      Environment = "Lab"
      Project     = "Project-V1"
      ManagedBy   = "Terraform"
    }
  }

  tags = {
    Name        = "aws-project-v1-web-launch-template"
    Environment = "Lab"
    Project     = "Project-V1"
    ManagedBy   = "Terraform"
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name = "aws-project-v1-web-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  vpc_zone_identifier = [
    module.network.public_subnet_a_id,
    module.network.public_subnet_b_id
  ]

  target_group_arns = [
    aws_lb_target_group.web_tg.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "aws-project-v1-asg-web"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "Lab"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "Project-V1"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "Owner"
    value               = "Project-V1"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "aws-project-v1-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "aws-project-v1-unhealthy-targets"
  alarm_description   = "Alert when the ALB has one or more unhealthy targets"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.web_tg.arn_suffix
    LoadBalancer = aws_lb.web_alb.arn_suffix
  }

  tags = {
    Environment = "Lab"
    Project     = "Project-V1"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_dashboard" "project_v1" {
  dashboard_name = "aws-project-v1-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ASG Average CPU Utilisation"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          stat   = "Average"

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              aws_autoscaling_group.web_asg.name
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ALB Target Health"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          stat   = "Maximum"

          metrics = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "TargetGroup",
              aws_lb_target_group.web_tg.arn_suffix,
              "LoadBalancer",
              aws_lb.web_alb.arn_suffix
            ],
            [
              "AWS/ApplicationELB",
              "UnHealthyHostCount",
              "TargetGroup",
              aws_lb_target_group.web_tg.arn_suffix,
              "LoadBalancer",
              aws_lb.web_alb.arn_suffix
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          title  = "ALB Request Count"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          stat   = "Sum"

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              aws_lb.web_alb.arn_suffix
            ]
          ]
        }
      }
    ]
  })
}


