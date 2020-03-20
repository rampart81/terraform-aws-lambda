###########################################################
## S3 Bucket for Lambda
###########################################################
resource "aws_s3_bucket" "lambda" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = var.s3_bucket_name
  acl    = "private"
  tags   = var.aws_s3_bucket_tags

  versioning {
    enabled = var.s3_bucket_versioning_enabled
  }
}

###########################################################
## Lambda
###########################################################
resource "aws_lambda_function" "lambda" {
  function_name = var.function_name
  s3_bucket     = var.s3_bucket_name
  s3_key        = "${var.build_version}/${var.build_file_name}"
  handler       = var.handler_name
  runtime       = var.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout
  role          = aws_iam_role.lambda.arn

  vpc_config {
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibility in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    security_group_ids = [var.vpc_config["security_group_ids"]]
    subnet_ids = [var.vpc_config["subnet_ids"]]
  }

  environment {
    variables = var.environment
  }
}

resource "aws_iam_role" "lambda" {
  name = var.project_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "lambda_logging" {
  name = "${var.project_name}-lambda-logging-policy"
  role = aws_iam_role.lambda.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:*",
        "logs:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

}

