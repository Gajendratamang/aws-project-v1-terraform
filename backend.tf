terraform {
  backend "s3" {
    bucket       = "aws-project-v1-tfstate-123456789012"
    key          = "project-v1/terraform.tfstate"
    region       = "eu-west-2"
    profile      = "aws-lab"
    use_lockfile = true
  }
}
