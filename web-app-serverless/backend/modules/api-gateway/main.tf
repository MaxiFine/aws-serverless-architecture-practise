locals {
  routes = {
    "GET /api/health"              = {}
    "GET /api/items"               = {}
    "POST /api/items"              = {}
  }

}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "${var.project_name}-api"
  stage_name    = var.stage_name
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-app-name", "authorization"]
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_credentials = true
    max_age          = 86400
  }

  create_domain_name    = false
  create_domain_records = false
  create_certificate    = false


  routes = merge(
     
    { for route_key, _ in local.routes :
      route_key => {
        integration = {
          uri                    = var.lambda_function_invoke_arn
          payload_format_version = "2.0"
          timeout_milliseconds   = 12000
        }
      }
    },
  )
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-api-gateway"
    }
  )

}


resource "aws_lambda_permission" "api_gateway_courses" {
  statement_id  = "AllowInvokeCourseHandler"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*"
}
