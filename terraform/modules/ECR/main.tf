###############################################################################
# AWS Elastic Container Registry (ECR) Repository
###############################################################################

resource "aws_ecr_repository" "buggy_repository" {
  name                 = var.reponame
  image_tag_mutability = "MUTABLE"  # Allows overwriting of image tags


  image_scanning_configuration {
    scan_on_push = true  # Scans images automatically when pushed to repository
  }

  # Configure encryption for the repository
  encryption_configuration {
    encryption_type = "KMS"  
  }

  # Add repository tags for better resource management
  tags = {
    Name        = var.reponame
    Environment = "Development"
    Terraform   = "true"
    Project     = "BuggyApp"
  }


  lifecycle {
    prevent_destroy = true  
  }
}