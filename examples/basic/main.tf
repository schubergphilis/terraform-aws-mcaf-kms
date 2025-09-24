provider "aws" {
  region = "eu-central-1"
}

module "basic" {
  source = "../.."

  name = "basic"
}
