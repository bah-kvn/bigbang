# BSF realm with BAH SSO

This Terraform module built to automate the setup of the Clients necessary for the Big Bang Monitoring module an existing Keycloak realm.  After running this module, the output can be used in the Big Bang configuration when enabling SSO on the monitoring stack with no further interaction with Keycloak.

## Requirements

Existing Keycloak realm with user access, i.e. an upstream IDP connection.

## Inputs

Input | Description
--- | ---
Realm ID | The ID of the realm to modify
Environment Prefix | The prefix used in the domain
Domain | The shared domain

## Outputs

Output | Description
--- | ---
alert_manager_client_id | Client ID for Alert Manager
alert_manager_client_secret | Client Secret for Alert Manager
grafana_client_id | Client ID for Grafana
grafana_client_secret | Client Secret for Grafana
prometheus_client_id | Client ID for Prometheus
prometheus_client_secret | Client Secret for Prometheus

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
- realm_id  
    The id (name) of the realm to modify
- env_prefix  
    The prefix to use for the domain, i.e. "env" in the address https://keycloak.env.bahsoftwarefactory.com
- domain  
    The domain including prefix, i.e. "env.bahsoftwarefactory.com" in the address https://keycloak.env.bahsoftwarefactory.com


Recommended to create a variables.tfvars file populated as such:

```txt
realm_id   = "value"
env_prefix = "value"
domain     = "value"
```

Run passing the variables file
```bash
terraform apply -var-file="variables.tfvars"
```

To get sensitive values
```bash
terraform output -json
```
