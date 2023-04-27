module "dev-stack" {
  source       = "./modules/stack"
  aws_env_name = "dev-eu"
  providers = {
    aws = aws.dev-eu
  }
}

module "qa-stack" {
  source       = "./modules/stack"
  aws_env_name = "qa-eu"
  providers = {
    aws = aws.qa-eu
  }
}

module "prod-stack" {
  source       = "./modules/stack"
  aws_env_name = "prod-eu"
  providers = {
    aws = aws.prod-eu
  }
}
