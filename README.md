# terraform-aws-lambda
Terraform module which creates lambda function on AWS

## NOTE
Ensure your AWS provider version is equal to or higher than 1.35.0
Otherwise you will get `vpc_config is <nil>` error if vpc_config variable is set.
For more info, see [here](https://github.com/terraform-providers/terraform-provider-aws/issues/443)

## Authors
Module managed by [Eun Woo Song](https://github.com/rampart81).

## License
Apache 2 Licensed. See [LICENSE](LICENSE) for full details.
