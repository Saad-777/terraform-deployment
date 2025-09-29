

resource "aws_security_group" "wordpresssg" {
  name        = " ${terraform.workspace}-${var.project_name}-wordpress-sg"
  description = "Allow HTTP and HTTPS traffic and SSH from anywhere"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${terraform.workspace}-wordpress-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allowHTTP" {
  security_group_id = aws_security_group.wordpresssg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.wordpresssg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.wordpresssg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports

}



resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-SecurityGroupForRDS"
  description = "Allow MySQL access from WordPress EC2"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from WordPress EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpresssg.id]
  }

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-SecurityGroupForRDS"
  }
}

resource "aws_secretsmanager_secret" "wordpress-secrets" {
  name        = "Saad-${terraform.workspace}-${var.project_name}-db-credentials"
  description = "RDS DB credentials for ${var.project_name} WordPress application"

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-db-credentials"
  }

}

resource "aws_secretsmanager_secret_version" "wordpress-db_credentials" {
  secret_id = aws_secretsmanager_secret.wordpress-secrets.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.wordpress-db.address
    db_name  = var.db_name
  })

}

resource "aws_db_instance" "wordpress-db" {
  identifier             = "${terraform.workspace}-${var.project_name}-wordpress-db"
  engine                 = "mariadb"
  engine_version         = "11.4.5"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = aws_security_group.rds_sg.id != null ? [aws_security_group.rds_sg.id] : []
  db_subnet_group_name   = var.db_subnet_group_name
  multi_az               = false
  storage_type           = "gp2"

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-wordpress-db"
  }

}




