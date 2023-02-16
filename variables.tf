locals {
  name   = "poc-${replace(basename(path.cwd), "_", "-")}"
  region = "us-east-1"
  ami    = "ami-0c9978668f8d55984" # Red Hat Enterprise Linux 9
  
  tags = {
    Project    = local.name
    GithubRepo = "tech-challenge"
    GithubOrg  = "dkoppel"
  }
}
