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

variable "github_owner" {
  type    = string
  default = ""
}

/* ----------------------------------------
    Resources
   ---------------------------------------- */

//resource "github_repository" "github_repo" {
//  for_each = var.create_github_repos ? toset(var.cloud_source_repos) : []
//
//  name                   = each.value
//  delete_branch_on_merge = true
//  visibility             = var.private_repositories ? "private" : "public"
//  auto_init              = true
//}


module "github_repository" {
  for_each = var.create_github_repos ? toset(var.cloud_source_repos) : []

  source          = "./modules/github_repository"
  repository_name = each.value

  private = true
}


/***********************************************
 Cloud Build - Apply triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "github_apply_trigger" {
  for_each    = var.create_github_repos_triggers ? toset(var.cloud_source_repos) : []
  project     = module.cloudbuild_project.project_id
  description = "${each.value} - apply"

  github {
    name = each.value
    owner = var.github_owner
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
    _IMAGE_TAG            = "0.14"
  }

  filename = var.cloudbuild_apply_filename
  depends_on = [
    module.github_repository,
  ]
}

/***********************************************
 Cloud Build - Plan triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "github_plan_trigger" {
  for_each    = var.create_github_repos_triggers ? toset(var.cloud_source_repos) : []
  project     = module.cloudbuild_project.project_id
  description = "${each.value} - plan"

  github {
    name  = each.value
    owner = var.github_owner
    pull_request {
      branch       = local.apply_branches_regex
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
    _IMAGE_TAG            = "0.14"
  }

  filename = var.cloudbuild_plan_filename
  depends_on = [
    module.github_repository,
  ]
}

/***********************************************
 Cloud Build - Destroy plan branch triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "github_destroy_plan_trigger" {
  for_each    = var.create_github_repos_triggers ? toset(var.cloud_source_repos) : []
  project     = module.cloudbuild_project.project_id
  description = "${each.value} - destroy plan"

  github {
    name  = each.value
    owner = var.github_owner
    pull_request {
      branch = local.destroy_branches_regex
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
    _IMAGE_TAG            = "0.14"
  }

  filename = var.cloudbuild_plan_filename
  depends_on = [
    module.github_repository,
  ]
}

/***********************************************
 Cloud Build - Destroy apply branch triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "github_destroy_apply_trigger" {
  for_each    = var.create_github_repos_triggers ? toset(var.cloud_source_repos) : []
  project     = module.cloudbuild_project.project_id
  description = "${each.value} - destroy apply"

  github {
    name  = each.value
    owner = var.github_owner
    push {
      branch = local.destroy_branches_regex
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
    _IMAGE_TAG            = "0.14"
  }

  filename = var.cloudbuild_plan_filename
  depends_on = [
    module.github_repository,
  ]
}
