terraform {
  required_version = ">= 1.5"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.240"
    }
  }
}

provider "alicloud" {
  profile = var.profile
  region  = var.region
}
