variable "realm_id" {
  type        = string
  description = "Realm id, seems to match the name 'bsf'"
}

variable "env_prefix" {
  type        = string
  description = "environment id prefix so we don't collide with clients in a shared instance"
}

variable "domain" {
  type        = string
  description = "Domain for apps, example 'env.bahsoftwarefactory.com'"
}
