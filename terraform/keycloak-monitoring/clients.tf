resource "keycloak_openid_client" "alert_manager" {
  realm_id  = var.realm_id
  client_id = "${var.env_prefix}-alertmanager"

  name    = "Alert Manager for ${var.env_prefix}"
  enabled = true

  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  base_url = "https://alertmanager.${var.domain}"

  valid_redirect_uris = [
    "https://alertmanager.${var.domain}/login/generic_oauth"
  ]

  login_theme = "keycloak"

  #extra_config = {
  #  "key1" = "value1"
  #  "key2" = "value2"
  #}
}

output "alert_manager_client_id" {
  value       = keycloak_openid_client.alert_manager.client_id
  sensitive   = false
  description = "Alert Manager client ID"
}

output "alert_manager_client_secret" {
  value       = keycloak_openid_client.alert_manager.client_secret
  sensitive   = true
  description = "Generated secret for the Alert Manager client"
}

resource "keycloak_openid_client" "prometheus" {
  realm_id  = var.realm_id
  client_id = "${var.env_prefix}-prometheus"

  name    = "Prometheus for ${var.env_prefix}"
  enabled = true

  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true

  base_url = "https://prometheus.${var.domain}"

  valid_redirect_uris = [
    "https://prometheus.${var.domain}/login/generic_oauth"
  ]

  login_theme = "keycloak"

  #extra_config = {
  #  "key1" = "value1"
  #  "key2" = "value2"
  #}
}

output "prometheus_client_id" {
  value       = keycloak_openid_client.prometheus.client_id
  sensitive   = false
  description = "Prometheus client ID"
}

output "prometheus_client_secret" {
  value       = keycloak_openid_client.prometheus.client_secret
  sensitive   = true
  description = "Generated secret for the prometheus client"
}

resource "keycloak_openid_client_scope" "client_scope_grafana" {
  realm_id               = var.realm_id
  name                   = "Grafana"
  description            = "Client scope for use by Grafana clients"
  include_in_token_scope = true
}

resource "keycloak_openid_user_attribute_protocol_mapper" "profile" {
  realm_id        = var.realm_id
  client_scope_id = keycloak_openid_client_scope.client_scope_grafana.id
  name            = "profile"

  user_attribute = "profile"
  claim_name     = "profile"

  claim_value_type     = "String"
  add_to_id_token      = true
  add_to_access_token  = true
  add_to_userinfo      = true
  multivalued          = false
  aggregate_attributes = false
}

resource "keycloak_openid_user_property_protocol_mapper" "email" {
  realm_id        = var.realm_id
  client_scope_id = keycloak_openid_client_scope.client_scope_grafana.id
  name            = "email"

  user_property = "email"
  claim_name    = "email"

  claim_value_type    = "String"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}

resource "keycloak_openid_user_realm_role_protocol_mapper" "realm_roles" {
  realm_id        = var.realm_id
  client_scope_id = keycloak_openid_client_scope.client_scope_grafana.id
  name            = "realm roles"

  claim_name          = "realm_access.roles"
  claim_value_type    = "String"
  add_to_id_token     = false
  add_to_access_token = true
  add_to_userinfo     = false
}

resource "keycloak_openid_user_client_role_protocol_mapper" "client_roles" {
  realm_id        = var.realm_id
  client_scope_id = keycloak_openid_client_scope.client_scope_grafana.id
  name            = "client roles"

  claim_name          = "resource_access.$${client_id}.roles"
  claim_value_type    = "String"
  add_to_id_token     = false
  add_to_access_token = true
  add_to_userinfo     = false
}

resource "keycloak_openid_user_property_protocol_mapper" "username" {
  realm_id        = var.realm_id
  client_scope_id = keycloak_openid_client_scope.client_scope_grafana.id
  name            = "username"

  user_property       = "username"
  claim_name          = "preferred_username"
  claim_value_type    = "String"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "groups" {
  realm_id        = var.realm_id
  client_scope_id = keycloak_openid_client_scope.client_scope_grafana.id
  name            = "groups"

  claim_name          = "groups"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}

resource "keycloak_openid_client" "grafana" {
  realm_id  = var.realm_id
  client_id = "${var.env_prefix}-grafana"

  name    = "Grafana for ${var.env_prefix}"
  enabled = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  base_url = "https://grafana.${var.domain}"

  valid_redirect_uris = [
    "https://grafana.${var.domain}/login/generic_oauth"
  ]

  login_theme = "keycloak"

  #extra_config = {
  #  "key1" = "value1"
  #  "key2" = "value2"
  #}
}

resource "keycloak_openid_client_default_scopes" "grafana_default_scopes" {
  realm_id  = var.realm_id
  client_id = keycloak_openid_client.grafana.id

  default_scopes = [
    "profile",
    "email",
    "roles",
    "web-origins",
    keycloak_openid_client_scope.client_scope_grafana.name,
  ]
}

output "grafana_client_id" {
  value       = keycloak_openid_client.grafana.client_id
  sensitive   = false
  description = "Grafana client ID"
}

output "grafana_client_secret" {
  value       = keycloak_openid_client.grafana.client_secret
  sensitive   = true
  description = "Generated secret for the Grafana client"
}

