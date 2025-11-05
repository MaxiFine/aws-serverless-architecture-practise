/*
Terraform Settings and AWS Provider Configuration

- terraform.required_providers: Ensures the AWS provider from HashiCorp 
  is installed, pinned to version ~> 6.0 for compatibility and stability.  

- terraform.backend "s3": Stores Terraform state remotely in an S3 bucket 
  for collaboration and persistence. The `use_lockfile = true` option 
  prevents simultaneous modifications of the state.  

- provider "aws": Configures the AWS provider to use the region specified 
  in the `var.region` variable.  

Purpose:
Establishes consistent Terraform behavior, remote state management, and 
the AWS provider connection details.  
*/

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "learning-bucket-terraform-state"
    key          = "web-app-serverless/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }


}

provider "aws" {
  region = var.region
  alias = "primary"
  profile = "default"
}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}