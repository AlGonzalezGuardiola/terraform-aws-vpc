module "vpc" {
  source = "../../"

  name = "example"
  cidr = "10.0.0.0/16"
  azs  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  public_subnets   = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  isolated_subnets = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # cost-saving for non-prod

  enable_flow_logs         = true
  flow_logs_retention_days = 365

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "example"
  }
}
