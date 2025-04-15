resource "aws_security_group" "sg" {
  description = "Allow inbound traffic"
  vpc_id      = var.config.vpc_id
  tags = merge(var.config.tags, {
    Name = format("%s-%s-${var.config.sg_name}", var.config.tags["environment"], var.config.tags["project"])
  })
}

resource "aws_security_group_rule" "allowed_ports_rules" {
  for_each = { for idx, port in var.config.allowed_ports : idx => port }

  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "allow_all_ping" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}


resource "aws_security_group_rule" "allowed_ips" {
  for_each          = var.config.allowed_ips
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [each.value]
  description       = each.key
  security_group_id = aws_security_group.sg.id
}
