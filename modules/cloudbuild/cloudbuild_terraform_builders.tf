/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


variable "builders_tag_map" {
  type    = map(object({
      terraform_version           = string,
      terraform_version_sha256sum = string,
  }))
  default = {
    "0.12" = {
      terraform_version = "0.12.29",
      terraform_version_sha256sum = "872245d9c6302b24dc0d98a1e010aef1e4ef60865a2d1f60102c8ad03e9d5a1d",
    },
    "0.13" = {
      terraform_version = "0.13.6",
      terraform_version_sha256sum = "55f2db00b05675026be9c898bdd3e8230ff0c5c78dd12d743ca38032092abfc9",
    },
    "0.14" = {
      terraform_version = "0.14.5",
      terraform_version_sha256sum = "2899f47860b7752e31872e4d57b1c03c99de154f12f0fc84965e231bc50f312f",
    }
  }
}


/***********************************************
 Cloud Build - Terraform builder
 ***********************************************/

resource "null_resource" "custom_cloudbuild_terraform_builder" {
  for_each = var.builders_tag_map
  
  triggers = {
    project_id_cloudbuild_project = module.cloudbuild_project.project_id
    terraform_version_sha256sum   = each.value.terraform_version_sha256sum
    terraform_version             = each.value.terraform_version
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud builds submit ${path.module}/cloudbuild_builder/ \
      --project ${module.cloudbuild_project.project_id} \
      --config=${path.module}/cloudbuild_builder/custom_cloudbuild.yaml \
      --substitutions=_IMAGE_TAG=${each.key},_TERRAFORM_VERSION=${each.value.terraform_version},_TERRAFORM_VERSION_SHA256SUM=${each.value.terraform_version_sha256sum},_TERRAFORM_VALIDATOR_RELEASE=${var.terraform_validator_release}
  EOT
  }
  depends_on = [
    google_project_service.cloudbuild_apis,
  ]
}

