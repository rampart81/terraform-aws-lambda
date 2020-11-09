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
## KMS For Lambda
###########################################################
data "aws_caller_identity" "current" { }
data "aws_iam_policy_document" "kms_policy" {
  ## IAM policy for KMS needs to have two statements:
  ## One for the current account (the actual user)
  ## and the other for the lambda iam role.
  ## For the current account, everything should be allowed.
  ## And the lambda iam role, only needed actions should be allowed, 
  ## which is to decrypt this case.
  statement {
    sid        = "1"
    effect     = "Allow"
    actions    = ["kms:*"]
    resources  = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    effect     = "Allow"
    actions    = ["kms:Decrypt"]
    resources  = ["*"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.lambda.arn]
    }
  }
}

resource "aws_kms_key" "lambda" {
  description         = "KSM Key For ${var.project_name} on AWS Lambda"
  is_enabled          = true
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_policy.json
}

##
## It would be nice to be able to use aliase for kms.
## But apparently, as of 2020 April, kms alise does not
## work for lambda as it throws the following error:
##
## InvalidParameterValueException: Lambda was unable to configure access to your environment variables 
## because the KMS key is invalid for CreateGrant. Please check your KMS key settings. 
## KMS Exception: InvalidArnException KMS Message: Key Aliases are not supported for this operation.
##
#resource "aws_kms_alias" "lambda" {
#  name          = "alias/${var.project_name}"
#  target_key_id = aws_kms_key.lambda.key_id
#}

###########################################################
## Lambda
###########################################################
resource "aws_lambda_function" "lambda" {
  function_name                  = var.function_name
  s3_bucket                      = var.s3_bucket_name
  s3_key                         = var.s3_key
  handler                        = var.handler_name
  runtime                        = var.runtime
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions
  role                           = aws_iam_role.lambda.arn
  layers                         = flatten(var.layers)

  vpc_config {
    security_group_ids = var.vpc_config["security_group_ids"]
    subnet_ids         = var.vpc_config["subnet_ids"]
  }

  environment {
    variables = var.environment
  }

  kms_key_arn = aws_kms_key.lambda.arn
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

#resource "aws_iam_role_policy" "lambda_kms_access" {
#  name = "${var.project_name}-kms-access-policy"
#  role = aws_iam_role.lambda.id

#  policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Action": [
#        "kms:Create*",
#        "kms:Describe*",
#        "kms:Enable*",
#        "kms:List*",
#        "kms:Put*",
#        "kms:Update*",
#        "kms:Revoke*",
#        "kms:Disable*",
#        "kms:Get*",
#        "kms:Delete*",
#        "kms:ScheduleKeyDeletion",
#        "kms:CancelKeyDeletion"
#      ],
#      "Resource": "*"
#    }
#  ]
#}
#EOF
#}

resource "aws_iam_role_policy" "lambda_network_access" {
  name = "${var.project_name}-lambda-network-access-policy"
  role = aws_iam_role.lambda.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "${var.project_name}-lambda-s3-access-policy"
  role = aws_iam_role.lambda.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllObjectActions",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": ["arn:aws:s3:::${var.s3_bucket_name}/*"]
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

