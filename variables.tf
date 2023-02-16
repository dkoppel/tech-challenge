locals {
  name   = "poc-${replace(basename(path.cwd), "_", "-")}"
  region = "us-east-1"

  tags = {
    Project    = local.name
    GithubRepo = "tech-challenge"
    GithubOrg  = "dkoppel"
  }
}
