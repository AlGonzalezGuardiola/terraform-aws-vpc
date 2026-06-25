locals {
  nat_count = var.enable_nat_gateway && length(var.public_subnets) > 0 ? (
    var.single_nat_gateway ? 1 : length(var.azs)
  ) : 0

  flow_logs_enabled = var.enable_flow_logs
  kms_key_arn       = var.flow_logs_kms_key_arn != "" ? var.flow_logs_kms_key_arn : null
}

# ── VPC ───────────────────────────────────────────────────────────────────────

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = var.name })
}

# ── Internet Gateway ──────────────────────────────────────────────────────────

resource "aws_internet_gateway" "this" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

# ── Subnets ───────────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(var.tags, {
    Name = "${var.name}-public-${var.azs[count.index]}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${var.azs[count.index]}"
    Tier = "private"
  })
}

resource "aws_subnet" "isolated" {
  count = length(var.isolated_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.isolated_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-isolated-${var.azs[count.index]}"
    Tier = "isolated"
  })
}

# ── NAT Gateways ──────────────────────────────────────────────────────────────

resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${var.azs[count.index]}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${var.azs[count.index]}"
  })

  depends_on = [aws_internet_gateway.this]
}

# ── Route Tables ──────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-public" })
}

resource "aws_route" "public_internet" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# One private route table per AZ — each points to its own NAT GW (or the single one).
resource "aws_route_table" "private" {
  count = length(var.private_subnets) > 0 ? length(var.azs) : 0

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-private-${var.azs[count.index]}" })
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway && length(var.private_subnets) > 0 ? length(var.azs) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Isolated subnets share one route table with no internet route.
resource "aws_route_table" "isolated" {
  count = length(var.isolated_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-isolated" })
}

resource "aws_route_table_association" "isolated" {
  count = length(var.isolated_subnets)

  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated[0].id
}

# ── Default Security Group ────────────────────────────────────────────────────
# Explicitly manage the default SG with no rules so it cannot be used accidentally.

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-default-sg-restrict" })
}

# ── VPC Flow Logs ─────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "flow_logs" {
  # checkov:skip=CKV_AWS_158:KMS encryption is optional and configurable via flow_logs_kms_key_arn
  count = local.flow_logs_enabled ? 1 : 0

  name              = "/aws/vpc/${var.name}/flow-logs"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = local.kms_key_arn

  tags = var.tags
}

resource "aws_iam_role" "flow_logs" {
  count = local.flow_logs_enabled ? 1 : 0

  name = "${var.name}-vpc-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = local.flow_logs_enabled ? 1 : 0

  name = "${var.name}-vpc-flow-logs"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = [
        aws_cloudwatch_log_group.flow_logs[0].arn,
        "${aws_cloudwatch_log_group.flow_logs[0].arn}:log-stream:*",
      ]
    }]
  })
}

resource "aws_flow_log" "this" {
  count = local.flow_logs_enabled ? 1 : 0

  vpc_id          = aws_vpc.this.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn

  tags = merge(var.tags, { Name = "${var.name}-flow-logs" })
}
