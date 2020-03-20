variable "build_version" {
}

variable "build_file_name" {
}

variable "project_name" {
}

variable "s3_bucket_name" {
}

variable "function_name" {
}

variable "handler_name" {
}

variable "s3_bucket_versioning_enabled" {
  default = true
}

variable "memory_size" {
  default = 384
}

variable "timeout" {
  default = 200
}

variable "runtime" {
  default = "python3.6"
}

variable "create_s3_bucket" {
  default = true
}

variable "aws_s3_bucket_tags" {
  type    = map(string)
  default = {}
}

variable "environment" {
  type    = map(string)
  default = {}
}

variable "vpc_config" {
  type = map(string)
  default = {
    security_group_ids = []
    subnet_ids         = []
  }
}

