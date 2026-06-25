variable "name" {
  description = "Name prefix applied to all resources."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 32
    error_message = "name must be between 1 and 32 characters."
  }
}

variable "cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "cidr must be a valid IPv4 CIDR block."
  }
}

variable "azs" {
  description = "List of Availability Zones to deploy into (e.g. [\"eu-west-1a\", \"eu-west-1b\"])."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 1 && length(var.azs) <= 6
    error_message = "Between 1 and 6 Availability Zones must be specified."
  }
}

# ── Subnets ──────────────────────────────────────────────────────────────────

variable "public_subnets" {
  description = "CIDR blocks for public subnets — one per AZ. Must match the length of azs."
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets (NAT-routed) — one per AZ. Must match the length of azs."
  type        = list(string)
  default     = []
}

variable "isolated_subnets" {
  description = "CIDR blocks for isolated subnets (no internet route) — one per AZ. Must match the length of azs."
  type        = list(string)
  default     = []
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IPs to instances launched in public subnets."
  type        = bool
  default     = false
}

# ── NAT Gateway ──────────────────────────────────────────────────────────────

variable "enable_nat_gateway" {
  description = "Provision NAT Gateways so private subnets can reach the internet."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ. Saves cost; not recommended for production."
  type        = bool
  default     = false
}

# ── VPC Flow Logs ─────────────────────────────────────────────────────────────

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Retention period in days for Flow Logs CloudWatch log group."
  type        = number
  default     = 365

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_logs_retention_days)
    error_message = "flow_logs_retention_days must be a valid CloudWatch Logs retention value."
  }
}

variable "flow_logs_kms_key_arn" {
  description = "Optional KMS key ARN to encrypt Flow Logs CloudWatch log group. Leave empty to skip encryption."
  type        = string
  default     = ""
}

# ── Tagging ───────────────────────────────────────────────────────────────────

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
