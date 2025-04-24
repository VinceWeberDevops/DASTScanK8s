variable "aws_region" {
    type = string
    default = "eu-west-2"
}

variable "reponame" {
    description = "Name of the ECR repository"
    type        = string
    default     = "buyggy-repository"
  
}