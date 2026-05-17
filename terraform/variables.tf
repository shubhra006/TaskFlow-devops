variable "region" {
  description = "AWS region — N. Virginia"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 size — m7i-flex.large = 2 vCPU, 8GB RAM"
  default     = "m7i-flex.large"
}

variable "key_name" {
  description = "Name of the key pair you created in AWS Console"
  default     = "taskflow-key"
  # Only change this if you used a different name when creating the key pair
}