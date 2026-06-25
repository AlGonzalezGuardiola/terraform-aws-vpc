# terraform-aws-vpc

Terraform module that provisions a production-ready 3-tier VPC on AWS.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  VPC  10.0.0.0/16                                       │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Public       │  │  Public       │  │  Public       │  │
│  │  10.0.0.0/24  │  │  10.0.1.0/24  │  │  10.0.2.0/24  │  │
│  │  (AZ-a)       │  │  (AZ-b)       │  │  (AZ-c)       │  │
│  │  [NAT GW]     │  │  [NAT GW]     │  │  [NAT GW]     │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                  │                  │          │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐  │
│  │  Private      │  │  Private      │  │  Private      │  │
│  │  10.0.10.0/24 │  │  10.0.11.0/24 │  │  10.0.12.0/24 │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Isolated     │  │  Isolated     │  │  Isolated     │  │
│  │  10.0.20.0/24 │  │  10.0.21.0/24 │  │  10.0.22.0/24 │  │
│  │  (no route)   │  │  (no route)   │  │  (no route)   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Tier breakdown:**
| Tier | Internet access | Use case |
|---|---|---|
| Public | Direct via IGW | Load balancers, bastion hosts, NAT Gateways |
| Private | Outbound only via NAT | Application servers, ECS tasks, Lambda |
| Isolated | None | Databases (RDS, ElastiCache), internal services |

## Features

- 3-tier subnet model: public / private / isolated
- One subnet per tier per Availability Zone
- Configurable NAT Gateway: one per AZ (HA) or single (cost-saving)
- VPC Flow Logs to CloudWatch Logs with optional KMS encryption
- Pre-commit hooks: `terraform fmt`, `terraform validate`, `tflint`, `checkov`, `terraform-docs`
- GitHub Actions CI: format check, validate, lint, security scan

## Usage

```hcl
module "vpc" {
  source = "github.com/AlGonzalezGuardiola/terraform-aws-vpc"

  name = "my-app"
  cidr = "10.0.0.0/16"
  azs  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  public_subnets   = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  isolated_subnets = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false # one NAT per AZ for production HA

  enable_flow_logs         = true
  flow_logs_retention_days = 30

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | ID of the VPC |
| `vpc_cidr` | CIDR block of the VPC |
| `public_subnet_ids` | IDs of the public subnets |
| `private_subnet_ids` | IDs of the private subnets |
| `isolated_subnet_ids` | IDs of the isolated subnets |
| `internet_gateway_id` | ID of the Internet Gateway |
| `nat_gateway_ids` | IDs of the NAT Gateways |
| `nat_public_ips` | Public Elastic IPs of the NAT Gateways |
| `public_route_table_id` | ID of the public route table |
| `private_route_table_ids` | IDs of the private route tables |
| `isolated_route_table_id` | ID of the isolated route table |
| `flow_log_id` | ID of the VPC Flow Log |

## Requirements

| Terraform | AWS Provider |
|---|---|
| >= 1.5 | >= 5.0 |

## License

MIT
