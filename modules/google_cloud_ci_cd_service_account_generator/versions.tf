terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.32.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.52.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.11.2"
    }
  }
}
