data "aws_caller_identity" "current" {}

locals {
  proxy_id = element(split(":", var.proxy_arn), length(split(":", var.proxy_arn)) - 1)
}



module "serverless_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  description   = "Lambda function for serverless management"
  function_name = "${var.project_name}-lambda-function"
  handler       = "main.lambda_handler"
  runtime       = "python3.12"
  # runtime       = "python3.13"
  source_path   = "${path.module}/lambda_functions/"
  timeout       = 60
  architectures = ["x86_64"]
  vpc_subnet_ids = var.private_subnet_ids
  vpc_security_group_ids = [var.security_group_id]


  environment_variables = {
      DB_PROXY_ENDPOINT = var.proxy_endpoint
      DB_SECRET_ARN     = var.db_secret_arn
      DB_USER          = var.db_username
      DB_HOST          = var.db_host
      DB_PORT          = var.db_port
      DB_NAME          = var.db_name
  }


  create_role                   = true
  attach_cloudwatch_logs_policy = true
  role_name                     = "${var.project_name}_serverless_lambda_exec"
  role_tags                     = var.tags

  attach_policy_statements = true
  policy_statements = [
    # VPC access permissions equivalent to AWSLambdaVPCAccessExecutionRole
    {
      effect = "Allow"
      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeSubnets",
        "ec2:DeleteNetworkInterface",
        "ec2:AssignPrivateIpAddresses",
        "ec2:UnassignPrivateIpAddresses",
      ]
      resources = ["*"]
    },
    {
        effect = "Allow"
        actions = [
          "rds-db:connect",
          "rds:DescribeDBInstances"
        ]
        # Use the DB resource-id (dbi-...) not the instance identifier
        resources = [
          "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${local.proxy_id}/${var.db_username}"
          ]
      },
      {
        effect = "Allow"
        actions = [
          "secretsmanager:GetSecretValue"
        ]
        resources = [var.db_secret_arn]
      },
      {
        effect = "Allow"
        actions = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        resources = ["*"]
      }
  ]
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-lambda-function"
    }
  )
}



