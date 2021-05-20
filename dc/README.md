# Basic EC2 instance (Domain controllers)

Configuration in this directory creates EC2 instances with different sets of arguments (with Elastic IP, with network interface attached, with credit specifications).

We can use those EC2 to be promoted to be a domain controllers with on prem AD

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which can cost money. Run `terraform destroy` when you don't need these resources.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.6 |
| aws | >= 2.65 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.65 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| ec2 | ../../ |  |

## Resources

| Name |
|------|
| [aws_ami](https://registry.terraform.io/providers/hashicorp/aws/2.65/docs/data-sources/ami) |
| [aws_eip](https://registry.terraform.io/providers/hashicorp/aws/2.65/docs/resources/eip) |
| [aws_kms_key](https://registry.terraform.io/providers/hashicorp/aws/2.65/docs/resources/kms_key) |
| [aws_network_interface](https://registry.terraform.io/providers/hashicorp/aws/2.65/docs/resources/network_interface) |
| [aws_placement_group](https://registry.terraform.io/providers/hashicorp/aws/2.65/docs/resources/placement_group) |
| [aws_subnet_ids](https://registry.terraform.io/providers/hashicorp/aws/2.65/docs/data-sources/subnet_ids) |
| [aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/2.65/docs/data-sources/vpc) |

## Inputs

No input.

## Outputs

| Name | Description |
|------|-------------|
| ebs\_block\_device\_volume\_ids | List of volume IDs of EBS block devices of instances |
| ids | List of IDs of instances |
| instance\_id | EC2 instance ID |
| instance\_public\_dns | Public DNS name assigned to the EC2 instance |
| placement\_group | List of placement group |
| public\_dns | List of public DNS names assigned to the instances |
| root\_block\_device\_volume\_ids | List of volume IDs of root block devices of instances |
| t2\_instance\_id | EC2 instance ID |
| tags | List of tags |
| vpc\_security\_group\_ids | List of VPC security group ids assigned to the instances |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
