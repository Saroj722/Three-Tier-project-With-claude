# --- RDS MySQL ---
# Lives in the private subnets only, no public IP, reachable only from
# the backend's security group (see security_groups.tf). This is the
# actual "no shortcuts to the data tier" enforcement - even if someone
# got shell access to the frontend container, this security group rule
# means they still couldn't reach the database directly.

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2 # allow modest autoscaling before you'd need to intervene
  storage_type          = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 3306

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Single-AZ, no read replica - fine for a learning/demo project. A real
  # production setup would set multi_az = true for automatic failover;
  # that roughly doubles RDS cost, which is why it's off here.
  multi_az = false

  backup_retention_period = 1
  skip_final_snapshot     = true # avoids a mandatory manual snapshot step when you `terraform destroy` this demo later
  deletion_protection     = false

  tags = {
    Name = "${var.project_name}-mysql"
  }
}
