#######################################
### Data sources for existing resources
#######################################
data "github_team" "software_factory" {
  slug = "software-factory"
}

data "github_team" "software_factory_admin" {
  slug = "software-factory-admin"
}

locals {
  owner     = "Solutions-Center"
  repo_name = github_repository.bsf_deployment_repository.name
}

##############
### Repository
##############
resource "github_repository" "bsf_deployment_repository" {
  name         = var.repository_name
  description  = var.repository_description
  homepage_url = "https://pages.github.boozallencsn.com/Solutions-Center/${var.repository_name}/"

  visibility = var.repository_visibility

  template {
    owner      = local.owner
    repository = "bsf-deployment-template"
  }

  topics = var.repository_topics

  delete_branch_on_merge = var.repository_delete_branch_on_merge
}

data "template_file" "readme" {
  template = file("${path.module}/resources/templates/README.md.tpl")
  vars = {
    REPO          = local.repo_name,
    README_OVERVIEW = var.readme_overview,
    README_INPUTS   = join("<br>", var.readme_inputs),
    README_OUTPUTS  = join("<br>", var.readme_outputs)
  }
}

resource "github_repository_file" "readme" {
  repository          = local.repo_name
  branch              = "main"
  file                = "README.md"
  overwrite_on_create = true
  content             = data.template_file.readme.rendered
  commit_message      = "Inital commit"
  #commit_author       = "Terraform User"
  #commit_email        = "terraform@example.com"
}

################
### Build Secret
################
resource "github_actions_secret" "build_secret" {
  repository      = local.repo_name
  secret_name     = "BUILD_SECRET"
  plaintext_value = var.build_secret
}

###################
### Add Team access
###################
resource "github_team_repository" "software_factory_maintainers" {
  team_id    = data.github_team.software_factory.id
  repository = local.repo_name
  permission = "maintain"
}

resource "github_team_repository" "software_factory_admins" {
  team_id    = data.github_team.software_factory_admin.id
  repository = local.repo_name
  permission = "admin"
}

############
### Branches
############
resource "github_branch_protection" "main_protection" {
  depends_on = [github_repository_file.readme]
  repository_id = local.repo_name

  pattern          = "main"
  enforce_admins   = true
  allows_deletions = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 1
  }
}

resource "github_branch" "branch_stage" {
  repository    = local.repo_name
  branch        = "stage"
  source_branch = "main"
}

resource "github_branch_protection" "stage_protection" {
  repository_id = local.repo_name

  pattern = github_branch.branch_stage.branch

  enforce_admins   = false
  allows_deletions = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 1
  }
}

resource "github_branch" "branch_dev" {
  repository    = var.repository_name
  branch        = "dev"
  source_branch = github_branch.branch_stage.branch
}

resource "github_branch_protection" "dev_protection" {
  repository_id = local.repo_name

  pattern = github_branch.branch_dev.branch

  enforce_admins   = false
  allows_deletions = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 1
  }
}

resource "github_branch" "branch_gh_pages" {
  repository    = local.repo_name
  branch        = "gh-pages"
  source_branch = "main"
}

resource "github_branch_protection" "gh_pages_protection" {
  repository_id = local.repo_name

  pattern = github_branch.branch_gh_pages.branch

  enforce_admins      = false
  allows_deletions    = false
  allows_force_pushes = true
}

####################################
### Issue labels for release drafter
####################################
resource "null_resource" "remove_default_labels" {
  #triggers = {
  #  run_once = "run_once"
  #}

  provisioner "local-exec" {
    interpreter = ["/bin/bash"]
    environment = {
      TOKEN = var.build_secret,
      OWNER = local.owner
      REPO  = local.repo_name
    }
    working_dir = "${path.module}/resources/scripts/"
    command     = "remove_default_labels.sh"
  }
}

resource "github_issue_label" "breaking_change" {
  depends_on  = [null_resource.remove_default_labels]
  repository  = local.repo_name
  name        = "breaking change"
  color       = "FBCA04"
  description = "When you make incompatible changes (major)"
}

resource "github_issue_label" "bug_fix" {
  depends_on  = [null_resource.remove_default_labels]
  repository  = local.repo_name
  name        = "bug fix"
  color       = "d73a4a"
  description = "Backwards compatible bug fixes (patch)"
}

resource "github_issue_label" "documentation" {
  depends_on  = [null_resource.remove_default_labels]
  repository  = local.repo_name
  name        = "documentation"
  color       = "0075ca"
  description = "Improvements or additions to documentation (patch)"
}

resource "github_issue_label" "enhancement" {
  depends_on  = [null_resource.remove_default_labels]
  repository  = local.repo_name
  name        = "enhancement"
  color       = "11FE9C"
  description = "Improvement or enhancement to existing functionality (minor)"
}

resource "github_issue_label" "maintenance" {
  depends_on  = [null_resource.remove_default_labels]
  repository  = local.repo_name
  name        = "maintenance"
  color       = "BFD4F2"
  description = "Fixing minor typos and/or dependencies (patch)"
}

resource "github_issue_label" "new_feature" {
  depends_on  = [null_resource.remove_default_labels]
  repository  = local.repo_name
  name        = "new feature"
  color       = "0E8A16"
  description = "New feature (minor)"
}

resource "github_issue_label" "skip_changelog" {
  depends_on  = [null_resource.remove_default_labels]
  repository  = local.repo_name
  name        = "skip-changelog"
  color       = "D4C5F9"
  description = "Do NOT include this in release notes"
}
