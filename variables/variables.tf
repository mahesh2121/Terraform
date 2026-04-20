#string variable 
variable "environment" {
    description = "The environment for which the infrastructure is being provisioned (e.g., dev, staging, prod)."
    type        = string
    default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, or prod."
  }
}

#Number of instance
variable "instance_count" {
    description = "The number of instances to create."
    type        = number
    default     = 1
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count < 10
    error_message = "Instance count must be greater than zero and less than ten."
  }
}


#Boolean variable
variable "enable_monitoring" {
    description = "Whether to enable monitoring for the instances."
    type        = bool
    default     = true
}   

#collection variables
#list of strings
variable "availability_zones" {
    description = "A list of availability zones to deploy the instances in."
    type        = list(string)
    default     = ["us-west-1a", "us-west-1b", "us-west-1c"]
  
}

#list of numberes
variable "allowed_ports" {
    description = "A list of allowed ports."
    type        = list(number)
    default     = [80, 443]
}

#set of unique values
variable "unique_tags" {
    description = "A set of unique tags for the instances."
    type        = set(string)
    default     = ["environment", "team", "project"]
}

#map strings
variable "tags" {
    description = "A map of tags to apply to the instances."
    type        = map(string)
    default     = {
        environment = "dev",
        team        = "backend",
        project     = "my-app"
    }
  
}

#map of numbers
variable "instance_type_cpu" {
    description = "A map of instance types to their corresponding CPU counts."
    type        = map(number)
    default     = {
        t2.micro   = 1,
        t2.small   = 1,
        t2.medium  = 2,
        t2.large   = 2
    }
  
}

#complex variable

variable "vpc_config" {
    description = "VPC configuration object"
    type = object({
      cidr_block = string
      enable_dns_support = bool
      enable_dns_hostnames = bool
      instance_tenancy = string
    })
    default = {
      cidr_block = "10.0.0.0/16"
      enable_dns_support = true
      enable_dns_hostnames = true
      instance_tenancy = "default"
    }
  }
  
#list of objects    
variable "subnets" {
    description = "list of subnets configuration"
    type = list(object({
      name = string
      cidr_block = string
      availability_zone = string
      public = bool
    }))
    default = [ {
      name = "public-subnet-1"
      cidr_block = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      public = true
    },
    {
        name = "private-subnet-1"
        cidr_block = "10.0.2.0/24"
        availability_zone = "us-east-1b"
        public = false
    }
]
}
    
    
  
