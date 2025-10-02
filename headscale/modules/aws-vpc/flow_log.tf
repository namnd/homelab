resource "aws_flow_log" "this" {
  vpc_id = aws_vpc.this.id

  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_lg.arn
  traffic_type    = "ALL"
}

resource "aws_cloudwatch_log_group" "vpc_lg" {
  name              = "/aws/vpc/${var.name}-flow-logs"
  retention_in_days = 365
}

data "aws_iam_policy_document" "vpc_flow_log_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name               = "${var.name}-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_log_assume_role.json
}

data "aws_iam_policy_document" "vpc_flow_log_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "vpc_flow_log_policy" {
  name   = "${var.name}-flow-log-policy"
  policy = data.aws_iam_policy_document.vpc_flow_log_policy.json
}

resource "aws_iam_role_policy_attachment" "vpc_flow_log_policy_attachment" {
  role       = aws_iam_role.vpc_flow_log_role.name
  policy_arn = aws_iam_policy.vpc_flow_log_policy.arn
}

