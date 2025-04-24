resource "aws_ecr_repository" "BuyggyRepository" {
  name                 = var.reponame
  image_tag_mutability = "MUTABLE"


  image_scanning_configuration {
    scan_on_push = true
  }
}