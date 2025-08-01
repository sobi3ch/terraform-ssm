terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }

    tls = {
      source = "hashicorp/tls"
      # Use a specific version to ensure compatibility
      # Adjust the version as needed
      version = ">= 4.0"
    }
  }
}
