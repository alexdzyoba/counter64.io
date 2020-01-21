provider "aws" {
  region  = "eu-west-1"
  profile = "counter64"
}

resource "aws_route53_zone" "primary" {
  name = "counter64.io"

  lifecycle {
    # Prevent destroy of the zone to avoid long DNS propagation
    prevent_destroy = true
  }
}
