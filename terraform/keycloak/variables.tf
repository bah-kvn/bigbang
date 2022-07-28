variable "realm_name" {
  type        = string
  default     = "bsf"
  description = "Realm name"
}

variable "realm_display_name" {
  type        = string
  default     = "BSF"
  description = "Realm display name"
}

variable "idp_alias" {
  type        = string
  default     = "bah-sso"
  description = "IDP alias"
}

variable "idp_display_name" {
  type        = string
  default     = "BAH SSO"
  description = "IDP display name"
}

variable "idp_entity_id" {
  type = string
  description = "The entity ID of this SP which is provided to the IDP"
}

variable "idp_single_sign_on_service_url" {
  type = string
  description = "The single sign on service url provided by the IDP"
}

variable "realm_admin_by_group_name" {
  type = string
  description = "This is a name of an AD group.  Users signing into this realm which have this group will be granted realm admin role."
}


