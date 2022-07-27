resource "keycloak_realm" "realm" {
  realm        = var.realm_name
  enabled      = true
  display_name = var.realm_display_name # optional
  #display_name_html = "" # optional

  user_managed_access = true       # optional
  ssl_required        = "external" # optional

  #login_theme = "base" # optional
  #access_code_lifespan = "1h" # optional

  #password_policy = "upperCase(1) and length(8) and forceExpiredPasswordChange(365) and notUsername" # optional

  # optional
  #attributes      = {
  #  mycustomAttribute = "myCustomValue"
  #}

  # optional ?
  #smtp_server {
  #  host = "smtp.example.com"
  #  from = "example@example.com"

  #  auth {
  #    username = "tom"
  #    password = "password"
  #  }
  #}

  # optional?
  #internationalization {
  #  supported_locales = [
  #    "en",
  #    "de",
  #    "es"
  #  ]
  #  default_locale    = "en"
  #}

  # optional?
  #security_defenses {
  #  headers {
  #    x_frame_options                     = "DENY"
  #    content_security_policy             = "frame-src 'self'; frame-ancestors 'self'; object-src 'none';"
  #    content_security_policy_report_only = ""
  #    x_content_type_options              = "nosniff"
  #    x_robots_tag                        = "none"
  #    x_xss_protection                    = "1; mode=block"
  #    strict_transport_security           = "max-age=31536000; includeSubDomains"
  #  }
  #  brute_force_detection {
  #    permanent_lockout                 = false
  #    max_login_failures                = 30
  #    wait_increment_seconds            = 60
  #    quick_login_check_milli_seconds   = 1000
  #    minimum_quick_login_wait_seconds  = 60
  #    max_failure_wait_seconds          = 900
  #    failure_reset_time_seconds        = 43200
  #  }
  #}

  # optional?
  #web_authn_policy {
  #  relying_party_entity_name = "Example"
  #  relying_party_id          = "keycloak.example.com"
  #  signature_algorithms      = ["ES256", "RS256"]
  #}
}


resource "keycloak_saml_identity_provider" "realm_saml_identity_provider" {
  realm                      = keycloak_realm.realm.id
  alias                      = var.idp_alias
  display_name               = var.idp_display_name
  entity_id                  = var.idp_entity_id
  single_sign_on_service_url = var.idp_single_sign_on_service_url

  # Settings specific to the BAH Azure AD Connection
  name_id_policy_format      = "Email"
  principal_type             = "SUBJECT"
  post_binding_response      = true
  post_binding_authn_request = true

  sync_mode   = "FORCE" # This is an opinionated choice to ensure we sync groups and name changes from the IDP on every login.
  store_token = false   # optional

  extra_config = {
    "allowCreate" : "true",
  }
}

resource "keycloak_custom_identity_provider_mapper" "email" {
  realm                    = keycloak_realm.realm.id
  name                     = "email"
  identity_provider_alias  = keycloak_saml_identity_provider.realm_saml_identity_provider.alias
  identity_provider_mapper = "saml-user-attribute-idp-mapper"

  # extra_config with syncMode is required in Keycloak 10+
  extra_config = {
    "UserAttribute" : "email",
    "syncMode" : "INHERIT",
    "user.attribute" : "email",
    "attribute.friendly.name" : "email",
    "Claim" : "email",
    "attribute.name" : "email"
  }
}

resource "keycloak_custom_identity_provider_mapper" "firstname" {
  realm                    = keycloak_realm.realm.id
  name                     = "firstname"
  identity_provider_alias  = keycloak_saml_identity_provider.realm_saml_identity_provider.alias
  identity_provider_mapper = "saml-user-attribute-idp-mapper"

  # extra_config with syncMode is required in Keycloak 10+
  extra_config = {
    "UserAttribute" : "firstname",
    "syncMode" : "INHERIT",
    "user.attribute" : "firstname",
    "attribute.friendly.name" : "firstname",
    "Claim" : "firstname",
    "attribute.name" : "firstname"
  }
}

resource "keycloak_custom_identity_provider_mapper" "lastname" {
  realm                    = keycloak_realm.realm.id
  name                     = "lastname"
  identity_provider_alias  = keycloak_saml_identity_provider.realm_saml_identity_provider.alias
  identity_provider_mapper = "saml-user-attribute-idp-mapper"

  # extra_config with syncMode is required in Keycloak 10+
  extra_config = {
    "UserAttribute" : "lastname",
    "syncMode" : "INHERIT",
    "user.attribute" : "lastname",
    "attribute.friendly.name" : "lastname",
    "Claim" : "lastname",
    "attribute.name" : "lastname"
  }
}

resource "keycloak_custom_identity_provider_mapper" "realm_admin" {
  realm                    = keycloak_realm.realm.id
  name                     = "realm_admin"
  identity_provider_alias  = keycloak_saml_identity_provider.realm_saml_identity_provider.alias
  identity_provider_mapper = "saml-advanced-role-idp-mapper"

  # extra_config with syncMode is required in Keycloak 10+
  extra_config = {
    "syncMode" : "INHERIT",
    "attributes" : "[{\"key\":\"groups\",\"value\":\"${var.realm_admin_by_group_name}\"}]",
    "role" : "realm-management.realm-admin"
  }
}
