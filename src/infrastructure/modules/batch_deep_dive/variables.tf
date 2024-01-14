variable "prefix" {
  type = string
  description = "Prefix for resource names"
}

variable "security_group_ids" {
  type = list(string)
  description = "List of security group IDs for the compute environment"  
}

variable "subnet_ids" {
  type = list(string)
  description = "List of subnet IDs for the compute environment"  
}

variable "bucket_name" {
  type = string
  description = "Name of the S3 bucket to use while running the job"  
}