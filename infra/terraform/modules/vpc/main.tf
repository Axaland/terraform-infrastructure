resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = var.name }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.name}-igw" }
}

resource "aws_subnet" "public" {
  for_each                = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-${each.key}" Tier = "public" }
}

resource "aws_subnet" "private" {
  for_each   = { for idx, cidr in var.private_subnet_cidrs : idx => cidr }
  vpc_id     = aws_vpc.this.id
  cidr_block = each.value
  tags = { Name = "${var.name}-private-${each.key}" Tier = "private" }
}

resource "aws_eip" "nat" {
  count      = var.enable_nat ? 1 : 0
  vpc        = true
  depends_on = [aws_internet_gateway.this]
  tags = { Name = "${var.name}-nat-eip" }
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = element(values(aws_subnet.public)[*].id, 0)
  tags = { Name = "${var.name}-nat" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

resource "aws_route_table" "private" {
  count  = var.enable_nat ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-private-rt" }
}

resource "aws_route" "private_nat" {
  count                  = var.enable_nat ? 1 : 0
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  for_each = var.enable_nat ? aws_subnet.private : {}
  route_table_id = aws_route_table.private[0].id
  subnet_id      = each.value.id
}
