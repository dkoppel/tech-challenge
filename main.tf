# Initialize a VPC and subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name               = local.name
  cidr               = "10.1.0.0/16"
  tags               = local.tags
  enable_nat_gateway = true

  azs             = ["${local.region}a", "${local.region}b"]
  private_subnets = ["10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.0.0/24", "10.1.1.0/24"]

  vpc_tags = {
    Name = "${local.name}-vpc"
  }
}

# Create a random id to prevent bucket name collisions.
resource "random_id" "id" {
  byte_length = 8
}

# Create a bucket and lifecycle rules
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

#Create folder objects
resource "aws_s3_object" "images" {
  key    = "Images/"
  bucket = module.s3-bucket.s3_bucket_id
}
resource "aws_s3_object" "logs" {
  key    = "Logs/"
  bucket = module.s3-bucket.s3_bucket_id
}

#Create a stand alone RHEL EC2 instance
resource "aws_instance" "standalone_server" {
  ami           = local.ami
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnets[1]
  key_name      = "access-key" #IMPORTANT: this key needs to be generated manually and securely stored in order to access instance.  See README.md

  tags = merge(local.tags, { Name = "${local.name}-standalone-rhel" })

  root_block_device {
    volume_size = 20
  }
  vpc_security_group_ids = [aws_security_group.app_ssh_sg.id]
}

#Create a load balancer target group
resource "aws_lb_target_group" "app_tg" {
  name     = "${local.name}-alb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  health_check {
    matcher = "200,403" #apache default page returns 403 rather than 200.
  }
}

#Create an Elastic Load Balancer, listener, and attachment
resource "aws_lb" "app_alb" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_lb_sg.id]
  subnets            = module.vpc.public_subnets
}
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
resource "aws_autoscaling_attachment" "app_attachment" {
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  lb_target_group_arn    = aws_lb_target_group.app_tg.arn
}

#Create an EC2 Launch configuration
resource "aws_launch_configuration" "app_launch_config" {
  name_prefix     = "${local.name}-app-"
  image_id        = local.ami
  instance_type   = "t2.micro"
  user_data       = file("user-data.sh")
  security_groups = [aws_security_group.app_instance_sg.id]
  lifecycle {
    create_before_destroy = true
  }
  root_block_device {
    volume_size = 20
  }
}

#Create an auto-scaling group
resource "aws_autoscaling_group" "app_asg" {
  name                 = "${local.name}-asg"
  min_size             = 2
  max_size             = 6
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.app_launch_config.name
  vpc_zone_identifier  = module.vpc.private_subnets
}

#Create security groups
resource "aws_security_group" "app_lb_sg" {
  name        = "${local.name}-lb-sg"
  description = "Allow all inbound HTTP traffic to LB"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "app_instance_sg" {
  name        = "${local.name}-instance-sg"
  description = "Allow LB traffic to app instances"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.app_lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "app_ssh_sg" {
  name        = "${local.name}-standalone-sg"
  description = "Allow inbound SSH access for standalone host"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}