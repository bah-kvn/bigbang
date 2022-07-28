#######################################
### Data sources for existing resources
#######################################
data "github_team" "software_factory_maintainer" {
  slug = var.repository_maintainer_team_name
}

data "github_team" "software_factory_admin" {
  slug = var.repository_admin_team_name
}

locals {
  repo_name = github_repository.repo.name
  default_branch = "main"
}

##############
### Repository
##############
resource "github_repository" "repo" {
  name         = var.repository_name
  description  = var.repository_description
  homepage_url = "https://${var.pages_url}/${var.github_owner}/${var.repository_name}/"
  visibility = var.repository_visibility
  has_issues = var.repository_has_issues
  topics = var.repository_topics
  

  template {
    owner      = var.repository_template.owner
    repository = var.repository_template.repository
  } 
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
  branch              = local.default_branch
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
  team_id    = data.github_team.software_factory_maintainer.id
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
resource "github_branch_protection" "default_protection" {
  depends_on = [github_repository_file.readme]
  repository_id = local.repo_name

  pattern          = local.default_branch
  enforce_admins   = true
  allows_deletions = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 1
  }
}

resource "github_branch" "branch_gh_pages" {
  repository    = local.repo_name
  branch        = "gh-pages"
  source_branch = local.default_branch
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
  count = var.use_custom_labels ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["/bin/bash"]
    environment = {
      TOKEN = var.build_secret,
      OWNER = var.github_owner
      REPO  = local.repo_name
    }
    working_dir = "${path.module}/resources/scripts/"
    command     = "remove_default_labels.sh"
  }
}

resource "github_issue_label" "custom_labels" {
  count = var.use_custom_labels ? length(var.custom_labels) : 0
  depends_on  = [null_resource.remove_default_labels]
  
  repository  = local.repo_name
  name        = var.custom_labels[count.index].name
  color       = var.custom_labels[count.index].color
  description = var.custom_labels[count.index].description
}

#####################
### Pre-Recieve Hooks
#####################
resource "null_resource" "enable_owasp_sedated_pre_recieve_hook" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash"]
    environment = {
      TOKEN = var.admin_pat,
      OWNER = var.github_owner,
      REPO  = local.repo_name,
      HOOKNAME= "OWASP SEDATED"
    }
    working_dir = "${path.module}/resources/scripts/"
    command     = "enable_pre-recieve_webhook.sh"
  }
}
