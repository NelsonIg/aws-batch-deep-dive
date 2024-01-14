variable "prefix" {
  type = string
  description = "Prefix for resource names" 
}

variable "subnet_ids" {
  type = list(string)
  description = "List of subnet IDs for the compute environment"    
}

variable "vpc_id" {
  type = string
  description = "VPC ID for the compute environment"      
}