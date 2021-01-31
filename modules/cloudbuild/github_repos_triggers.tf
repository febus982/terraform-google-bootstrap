/* ----------------------------------------
    Variables & locals
   ---------------------------------------- */

variable "private_repositories" {
  type    = bool
  default = true
}

variable "create_github_repos" {
  type    = bool
  default = false
}

variable "create_github_repos_triggers" {
  type    = bool
  default = false
}

/* ----------------------------------------
    Resources
   ---------------------------------------- */

resource "github_repository" "github_repo" {
  for_each = var.create_github_repos ? toset(var.cloud_source_repos) : []

  name                   = each.value
  delete_branch_on_merge = true
  visibility             = var.private_repositories ? "private" : "public"
  auto_init              = true
}


/***********************************************
 Cloud Build - Master branch triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "github_master_trigger" {
  for_each    = var.create_cloud_source_repos ? toset(var.cloud_source_repos) : []
  project     = module.cloudbuild_project.project_id
  description = "${each.value} - terraform apply."

  github {
    name = each.value
    push {
      branch = local.apply_branches_regex
    }
  }

  substitutions = {
    _ORG_ID               = var.org_id
    _BILLING_ID           = var.billing_account
    _DEFAULT_REGION       = var.default_region
    _TF_SA_EMAIL          = var.terraform_sa_email
    _STATE_BUCKET_NAME    = var.terraform_state_bucket
    _ARTIFACT_BUCKET_NAME = google_storage_bucket.cloudbuild_artifacts.name
    _TF_ACTION            = "apply"
  }

  filename = var.cloudbuild_apply_filename
  depends_on = [
    github_repository.github_repo,
  ]
}

/***********************************************
 Cloud Build - Non Master branch triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "github_non_master_trigger" {
  for_each    = var.create_cloud_source_repos ? toset(var.cloud_source_repos) : []
  project     = module.cloudbuild_project.project_id
  description = "${each.value} - terraform plan."

  github {
    name = each.value
    push {
      branch       = local.apply_branches_regex
      invert_regex = true
    }
  }

  substitutions = {
    _ORG_ID               = var.org_id
    _BILLING_ID           = var.billing_account
    _DEFAULT_REGION       = var.default_region
    _TF_SA_EMAIL          = var.terraform_sa_email
    _STATE_BUCKET_NAME    = var.terraform_state_bucket
    _ARTIFACT_BUCKET_NAME = google_storage_bucket.cloudbuild_artifacts.name
    _TF_ACTION            = "plan"
  }

  filename = var.cloudbuild_plan_filename
  depends_on = [
    github_repository.github_repo,
  ]
}

output "github_repos" {
  description = "List of Github Repos created by the module, linked to Cloud Build triggers."
  value       = github_repository.github_repo
}
