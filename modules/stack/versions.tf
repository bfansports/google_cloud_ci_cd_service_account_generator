terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.63.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.64.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
  }
}
