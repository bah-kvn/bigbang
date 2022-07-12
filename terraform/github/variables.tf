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
  description = "Secret with access to repo."
}

### Defaults which may be overidden

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

variable "repository_topics" {
  type        = list(any)
  default     = ["software-factory"]
  description = "List of topics for the repository."
}

variable "repository_visibility" {
  type        = string
  default     = "private"
  description = "Visiblity, 'public', 'private', or 'internal'"
}

variable repository_delete_branch_on_merge {
  type        = bool
  default     = true
  description = "Deleate head branch on merge."
}

