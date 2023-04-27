# One provider per AWS account
provider "aws" {
  profile = "dev-eu"
  region  = "eu-west-1"
  alias   = "dev-eu"
}
provider "aws" {
  profile = "qa-eu"
  region  = "eu-west-1"
  alias   = "qa-eu"
}
provider "aws" {
  profile = "prod-eu"
  region  = "eu-west-1"
  alias   = "prod-eu"
}
