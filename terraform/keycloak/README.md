# BSF realm with BAH SSO

This Terraform module built to automate the setup of the BSF realm in a new Keycloak instance.  Realm will be created with the IDP connection for BAH SSO built in and ready to go.

## Requirements

BAH Azure AD Enterprise App connection - SAML 2.0

Reach out to sso@bah.com for assistance getting a new Azure Enterprise App set up.

If you are an engineer on BSF, we already have 1 prod connection and 2 test connections in place.  See our internal confluence page for details.

## Inputs

Input | Description
--- | ---
Keycloak Service Account User | Client Secret which allows Terraform to create and configure a realm in Keycloak
SP Entity ID | This is a unique ID to be provided to the IDP which will identify this instance of Keycloak
IDP SSO Login URL | This is the SAML Login URL, provided by the IDP
Admin Group | This is the name of the group which will auto assign users to be realm admin's



## Outputs

None

## Using module

User must first login to the admin console and create a client for use by Terraform

1. Create a new client using the openid-connect protocol.
2. Update the client you just created:  
    Set Access Type to confidential.  
    Set Standard Flow Enabled to OFF.  
    Set Direct Access Grants Enabled to OFF  
    Set Service Accounts Enabled to ON.  
    SAVE changes
3. Navigate to Service Account Roles tab
    Assign 'admin' role
4. Navigate to Credentials tab
    Take note of the Secret for next step.

Modify main.tf and configure the provider by providing the client secret and url to your keycloak instance.

```txt
provider "keycloak" {
  client_id = "terraform"
  client_secret = "secret-data"
  url = "https://{keycloak-address}"
}
```

An alternate to saving the client secret in the provider config is to use an env variable as follows:

```bash
export KEYCLOAK_CLIENT_SECRET=secret-data
```

User will need to provide variables for: 
- idp_entity_id  
    The entity ID of this SP which is provided to the IDP
- idp_single_sign_on_service_url  
    The single sign on service url provided by the IDP
- realm_admin_by_group_name  
    This is a name of an AD group.  Users signing into this realm which have this group will be granted realm admin role.

Recommended to create a variables.tfvars file populated as such:

```txt
idp_entity_id                  = "value"
idp_single_sign_on_service_url = "value"
realm_admin_by_group_name      = "value"
```

Run passing the variables file
```
terraform apply -var-file="variables.tfvars"
```