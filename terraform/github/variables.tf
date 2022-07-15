### Mandatory User Input

variable "repository_name" {
  type        = string
  description = "Name of the repository."
}

variable "repository_description" {
  type        = string
  description = "Description of the repository."
}

variable "build_secret" {
  type        = string
  description = "Git PAT to put in repo Secret, used to run actions."
}

variable "admin_pat" {
  type = string
  description = "Git Pat to configure repo.  Must have admin:pre_receive_hook."
}

### Defaults which may be overidden by user

variable "github_base_url" {
  type        = string
  default     = "https://github.boozallencsn.com/"
  description = "The base url for the GitHub instance being targeted"
}

variable "github_owner" {
  type        = string
  default     = "Solutions-Center"
  description = "The user or org which owns the repo being created"
}

variable "pages_url" {
  type = string
  default = "pages.github.boozallencsn.com"
  description = "Base url of where github pages will be hosted."
}

variable "repository_admin_team_name" {
  type = string
  default = "software-factory-admin"
  description = "The team name which will be assigned as Admin of the repo."
}

variable "repository_maintainer_team_name" {
  type = string
  default = "software-factory"
  description = "The team name which will be assigned as Maintainer of the repo."
}

variable "repository_visibility" {
  type        = string
  default     = "private"
  description = "Visiblity, 'public', 'private', or 'internal'"
}

variable "repository_has_issues" {
  type = bool
  default = true
  description = "Enable GitHub issues feature on the repository"
}

variable "repository_topics" {
  type        = list(string)
  default     = ["software-factory"]
  description = "List of topics for the repository."
}

variable "repository_template" {
  type = map
  default = {
    owner = "Solutions-Center",
    repository = "bsf-deployment-template"
  }
}

variable "use_custom_labels" {
  type = bool
  default = true
  description = "Flag to use custom labels.  Set to false to use the org's pre-defined labels."
}

variable "custom_labels" {
  type = list(any)
  default = [
    {
      name = "breaking change"
      color = "FBCA04"
      description = "When you make incompatible changes (major)"
    },
    {
      name = "bug fix"
      color = "d73a4a"
      description = "Backwards compatible bug fixes (patch)"
    },
    {
      name = "documentation"
      color = "0075ca"
      description = "Improvements or additions to documentation (patch)"
    },
    {
      name = "enhancement"
      color = "11FE9C"
      description = "Improvement or enhancement to existing functionality (minor)"
    },
    {
      name = "maintenance"
      color = "BFD4F2"
      description = "Fixing minor typos and/or dependencies (patch)"
    },
    {
      name = "new feature"
      color = "0E8A16"
      description = "New feature (minor)"
    },
    {
      name = "skip-changelog"
      color = "D4C5F9"
      description = "Do NOT include this in release notes"
    }
  ]
}

# Variables for the README.md template
variable "readme_overview" {
  type        = string
  default     = "This is a repo for one of the BSF deployment steps.  This text should be overriden from terraform, or updated by the repo owner after it has been created."
  description = "Override this value with your README.md overview statement."
}

variable "readme_inputs" {
  type        = list(string)
  default     = ["one", "two", "three"]
  description = "Override this list with your repo's required inputs."
}

variable "readme_outputs" {
  type        = list(string)
  default     = ["one", "two", "three"]
  description = "Override this list with your repo's outputs."
}

