resource "aws_security_group" "cluster_sg" {
  name   = "eks-cluster-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "eks-cluster-sg" }
}

resource "aws_security_group" "node_sg" {
  name   = "eks-node-sg"
  vpc_id = var.vpc_id

  ingress {
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  security_groups = [aws_security_group.cluster_sg.id]
}


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "eks-node-sg" }
}
