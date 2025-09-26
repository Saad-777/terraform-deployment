

resource "aws_iam_role" "wordpress_secrets_role" {
  name = "${terraform.workspace}-${var.project_name}-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "wordpress_secrets_policy" {
  name = "${terraform.workspace}-${var.project_name}-secrets-policy"
  role = aws_iam_role.wordpress_secrets_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "cloudwatch:PutMetricData",
          "ec2:DescribeTags"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "wordpress_instance_profile" {
  name = "${terraform.workspace}-${var.project_name}-instance-profile"
  role = aws_iam_role.wordpress_secrets_role.name
}


resource "aws_launch_template" "wordpress" {
  name = "${terraform.workspace}-${var.project_name}-wordpress-launch-template"

  image_id      = "ami-08982f1c5bf93d976" # Replace with latest Amazon Linux 2023 AMI if needed
  instance_type = "t2.micro"
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.wordpress_sg_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.wordpress_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    RDS_HOST   = var.rds_host
    SECRET_ARN = var.secrets_arn
    AWS_REGION = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${terraform.workspace}-wordpress-instance"
    }
  }
}

resource "aws_autoscaling_group" "wordpress_asg" {
  name             = "${terraform.workspace}-${var.project_name}-wordpress-asg"
  desired_capacity = 1
  min_size         = 1
  max_size         = 4

  vpc_zone_identifier       = var.public_subnet_ids # List of public subnet IDs for EC2 instances
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest" # Always use the latest version of the launch template
  }

  target_group_arns = var.target_group_arns # ALB Target Group(s) for WordPress
  force_delete      = true                  # Allows ASG deletion even if EC2 instances are still running

  tag {
    key                 = "Name"
    value               = "${terraform.workspace}-${var.project_name}-wordpress-instance"
    propagate_at_launch = true
  }
}






resource "aws_autoscaling_policy" "wordpress_scale_out" {
  name                   = "${terraform.workspace}-${var.project_name}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.wordpress_asg.name

  scaling_adjustment = 1 # Add 1 instance
  adjustment_type    = "ChangeInCapacity"
  cooldown           = 120 # 2 minutes cooldown
}

resource "aws_autoscaling_policy" "wordpress_scale_in" {
  name                   = "${terraform.workspace}-${var.project_name}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.wordpress_asg.name

  scaling_adjustment = -1 # Remove 1 instance
  adjustment_type    = "ChangeInCapacity"
  cooldown           = 120 # 2 minutes cooldown
}


resource "aws_cloudwatch_metric_alarm" "wordpress_mem_high_alarm" {
  alarm_name          = "${terraform.workspace}-${var.project_name}-mem-high"
  alarm_description   = "Scale out when ASG memory usage > 40% for 2 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 60
  threshold           = 40
  statistic           = "Average"
  namespace           = "CWAgent"
  metric_name         = "mem_used_percent"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.wordpress_scale_out.arn]
}


resource "aws_cloudwatch_metric_alarm" "wordpress_mem_low_alarm" {
  alarm_name          = "${terraform.workspace}-${var.project_name}-mem-low"
  alarm_description   = "Scale in when ASG memory usage < 40% for 2 minutes"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  period              = 60
  threshold           = 40
  statistic           = "Average"
  namespace           = "CWAgent"
  metric_name         = "mem_used_percent"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.wordpress_scale_in.arn]
}

