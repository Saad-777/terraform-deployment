
resource "aws_lb_target_group" "wordpress_tg" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200-399"
  }

  tags = {
    Name    = "${terraform.workspace}-${var.project_name}-tg"
    Project = var.project_name
  }
}


resource "aws_lb" "wordpress_alb" {
  name               = "${terraform.workspace}-${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"


  subnets = var.public_subnet_ids

  security_groups = [var.wordpress_sg_id]

  tags = {
    Name    = "${terraform.workspace}-${var.project_name}-alb"
    Project = var.project_name
  }
}

resource "aws_lb_listener" "wordpress_listener" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
  }
}





