# tech-challenge #

The purpose of this technical challenge is to demonstrate a working knowledge of Terraform through practical application.  This terraform configuration provisions a simple Proof of Concept infrastructure in the AWS cloud, meeting the following requirements:

1. A VPC containing 4 subnets, distributed amongst 2 availability zones, two private and two public.
2. An Application load balancer (HTTP).
3. An auto scaling group of application webservers running apache across two private subnets across multiple availability zones.
4. A standalone Red Hat instance accessible in a public VPC.
5. An S3 bucket containing /logs and /images with individual lifecycle policies

## Prerequisites ##

In addition to a local copy of this repository, you must have a working local install of AWS CLI, Terraform CLI (1.2.0+) and an AWS account with IAM access allowing creation of resources.  AWS_ACCESS_KEY_ID environment variable must be set with a working AWS CLI key.  For more information about establishing an active session and access key, see https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html

You will need access to create resources in US-East-1.
In order to access instances, you will need to pre-generate an RSA keypair called "access-key" in us-east-1 and save it locally.

## Usage ##

Once all prerequisites are met, this configuration can be applied as follows:

```
$terraform init
$terraform apply
```

## Sources, references, examples used:
https://developer.hashicorp.com/tutorials/library?product=terraform
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build
https://developer.hashicorp.com/terraform/tutorials/aws/aws-asg
https://github.com/terraform-aws-modules/terraform-aws-vpc
https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/examples/simple-vpc
https://github.com/terraform-aws-modules/terraform-aws-s3-bucket
https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
https://registry.terraform.io/providers/hashicorp/aws/latest/docs
https://registry.terraform.io/namespaces/terraform-aws-modules