terraform {
  backend "s3" {
    bucket = "shopping-production.chottu.shop"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}
