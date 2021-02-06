variable "repository_name" {
  type    = string
}

variable "github_owner" {
  type    = string
  default = ""
}

variable "private" {
  type    = bool
  default = true
}

variable "enable_branch_protection" {
  type    = bool
  default = false
}

variable "terraform_apply_branches" {
  description = "List of git branches configured to run terraform apply Cloud Build trigger, protection will be applied."
  type        = list(string)

  default = [
    "apply"
  ]
}

variable "create_cloudbuild_triggers" {
  type    = bool
  default = false
}
