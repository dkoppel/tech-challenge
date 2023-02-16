module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = local.name
  cidr = "10.1.0.0/16"

  azs             = ["${local.region}a", "${local.region}b"]
  private_subnets = ["10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.0.0/24", "10.1.1.0/24"]

  tags = local.tags

  vpc_tags = {
    Name = "${local.name}-vpc"
  }
}

# We need to add a random seed to bucket names to prevent bucket name collisions.
resource "random_id" "id" {
  byte_length = 8
}

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.7.0"

  bucket = "${local.name}-bucket-${random_id.id.hex}"

  tags = local.tags

  lifecycle_rule = [
    {
      id      = "images"
      enabled = true

      filter = {
        prefix = "Images/"
      }

      transition = [
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
    },
    {
      id      = "logs"
      enabled = true

      filter = {
        prefix = "Logs/"
      }

      expiration = {
        days = 90
      }
    }
  ]
}

resource "aws_instance" "standalone_server" {
  ami           = "ami-0c9978668f8d55984" # Red Hat Enterprise Linux 9
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnets[1]
  key_name      = "access-key" #IMPORTANT: this key needs to be generated manually and securely stored in order to access instance.  See README.md

  tags = merge(local.tags, { Name = "${local.name}-standalone-rhel" })

  root_block_device {
    volume_size = 20
  }

}
