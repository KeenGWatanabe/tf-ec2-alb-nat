resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.vpc_endpoint.id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.vpc_endpoint.id]
}
