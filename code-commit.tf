resource "aws_codecommit_repository" "code_repo" {
  repository_name = "MainRepository"
  description     = "Our main repository"
}