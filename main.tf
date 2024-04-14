resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.env}-rds"
  engine                  = var.engine
  engine_version          = var.engine_version
  database_name           = var.database_name
  master_username         = data.aws_ssm_parameter.user.value
  master_password         = data.aws_ssm_parameter.pass.value
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  db_subnet_group_name = aws_db_subnet_group.main.name
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.main.id]

  tags = merge(
    var.tags,
    { Name = "${var.env}-subnet-group" }
  )

}

resource "aws_security_group" "main" {
  name        = "rds-${var.env}"
  description = "rds-${var.env}"
  vpc_id      = var.vpc_id

  ingress {
    description = "RDS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.allow_subnets
  }

  tags = merge(
    var.tags,
    { Name = "rds-${var.env}" }
  )
}


#resource "aws_vpc_security_group_ingress_rule" "ingress2" {
#  security_group_id = aws_security_group.main.id
#  cidr_ipv4         = var.allow_app_to
#  from_port         = var.port
#  ip_protocol       = "tcp"
#  to_port           = var.port
#  description = "APP"
#}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_rds_cluster_instance" "main" {
  count              = var.no_of_instances
  identifier         = "${var.env}-rds-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.env}-rds"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    { Name = "${var.env}-subnet-group" }
  )
}

resource "aws_ssm_parameter" "rds_endpoint" {
  name  = "${var.env}.rds.endpoint"
  type  = "String"
  value = aws_rds_cluster.main.endpoint
}