resource "github_repository" "repository" {
  name                   = var.repository_name
  delete_branch_on_merge = true
  visibility             = var.private ? "private" : "public"
  auto_init              = true
}

resource "github_branch" "deploy_branch" {
  for_each = toset(var.terraform_apply_branches)

  branch     = each.value
  repository = github_repository.repository.name

  depends_on = [github_repository.repository]
}

resource "github_branch_protection" "branch_protection" {
  for_each = var.enable_branch_protection ? github_branch.deploy_branch : {}

  repository_id = github_repository.repository.id
  pattern       = each.value.branch

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 1
  }

  allows_deletions    = false
  allows_force_pushes = false

  depends_on = [github_branch.deploy_branch]
}
