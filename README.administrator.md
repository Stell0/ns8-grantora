# Grantora Administrator Documentation for NethServer 8

## Overview

`ns8-grantora` installs Grantora as an Agent Capability Gateway on NethServer 8. It exposes only the authenticated runtime gateway through Traefik and keeps Grantora Admin API, APISIX Admin API, PostgreSQL, and etcd private. The module UI provides these pages: **Status**, **Settings**, **Workspace**, **Agents**, **Resources**, **Activity**, and **About**. 

Runtime public surface:

```text
https://<grantora-host>/v1/*
```

Administrative operations are performed through the NethServer 8 web UI or NS8 actions, not by exposing Grantora Admin API.

---

## Initial configuration from web interface

Open the Grantora application from the NethServer 8 cluster-admin UI.

### 1. Settings

Go to **Settings** and configure the module.

#### Public route

| Field         | Meaning                                                                   |
| ------------- | ------------------------------------------------------------------------- |
| Host          | Public FQDN used by agents, for example `grantora.example.org`. Required. |
| Let’s Encrypt | Enables or disables NS8 Traefik certificate automation.                   |

The UI validates the host as a fully qualified hostname. It must contain at least one dot and valid DNS labels. 

#### Runtime settings

| Field           |  Default | Meaning                                                                                              |
| --------------- | -------: | ---------------------------------------------------------------------------------------------------- |
| Log level       |   `INFO` | Grantora application log verbosity. Allowed values: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`. |
| Metrics enabled | disabled | Enables the private metrics endpoint. Metrics remain pod-local.                                      |

Allowed log levels are defined by the UI as `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`. 

#### User provider

| Field              |      Default | Meaning                                                     |
| ------------------ | -----------: | ----------------------------------------------------------- |
| User domain        |         none | NS8 account domain used to synchronize users into Grantora. |
| Sync users enabled |     disabled | Enables periodic LDAP user synchronization.                 |
| Sync interval      | `60` minutes | Interval for periodic sync. Valid range: `1–1440`.          |

If user sync is enabled, a user domain is required. LDAP usernames are imported as Grantora external user IDs. LDAP passwords are not stored in Grantora.

#### Runtime policy

| Field                          |      Default | Valid range | Meaning                                   |
| ------------------------------ | -----------: | ----------: | ----------------------------------------- |
| Runtime rate limit count       |       `1000` | `1–1000000` | Request quota for public runtime traffic. |
| Runtime rate limit time window | `60` seconds |   `1–86400` | APISIX fixed-window period.               |
| Audit retention days           |        `365` |    `1–3650` | Audit event retention.                    |
| Usage retention days           |        `365` |    `1–3650` | Usage event retention.                    |

#### Upstream defaults

| Field               |      Default |    Valid range | Meaning                                                     |
| ------------------- | -----------: | -------------: | ----------------------------------------------------------- |
| TLS verify          |      enabled |        boolean | Verify TLS certificates when calling upstream applications. |
| Upstream timeout    | `30` seconds |        `1–600` | Total provider request timeout.                             |
| Connect timeout     | `10` seconds |        `1–120` | Provider connection timeout.                                |
| Max response bytes  |   `10485760` | `1–1073741824` | Maximum upstream response size.                             |
| Read retry attempts |          `2` |         `0–10` | Retry count for read-only upstream operations.              |

The Settings page loads current configuration through `get-configuration` and saves through `configure-module`.  

Click **Save**.

---

### 2. Status

Go to **Status** and verify the instance.

The page shows:

| Section              | What to check                                                       |
| -------------------- | ------------------------------------------------------------------- |
| Public runtime URL   | Must point to the configured host.                                  |
| Pod                  | Pod state must be running.                                          |
| Running version      | Current Grantora upstream version.                                  |
| Selected user domain | Configured LDAP/account domain, if any.                             |
| Metrics              | Enabled/disabled state.                                             |
| Retention            | Audit and usage retention windows.                                  |
| Runtime checks       | `/healthz`, `/readyz`, APISIX sync, and metrics probe when enabled. |
| User sync            | Last sync, imported users, disabled users, errors, last error.      |
| Systemd units        | State of Grantora user units.                                       |
| Containers           | State, health, version, and image for each container.               |
| Operations           | Log backend, structured logs, retention timer, helper commands.     |

The Status page also provides **Refresh** and **Sync users now** actions. User sync is disabled in the UI when sync is not enabled in Settings. 

---

### 3. Workspace

Go to **Workspace**.

Use this page to bootstrap the default Grantora workspace and inspect global administrative resources.

#### Bootstrap workspace

Default form values:

| Field                    | Default                      |
| ------------------------ | ---------------------------- |
| Workspace slug           | `default`                    |
| Workspace display name   | `Grantora Default Workspace` |
| Provider type            | empty                        |
| Side-effect role enabled | disabled                     |

Click **Bootstrap workspace**.

This creates or updates the default workspace and default roles. The page then shows:

| Section               | Contents                                                             |
| --------------------- | -------------------------------------------------------------------- |
| Workspace ID          | Current default workspace ID.                                        |
| Templates             | Number of available capability templates.                            |
| Last bootstrap update | Last bootstrap timestamp.                                            |
| Workspaces            | Slug, display name, status, ID.                                      |
| Roles                 | Role slug, permissions, status.                                      |
| Capability templates  | Template ID, name, provider type, risk class, required secret types. |

The Workspace page calls `get-admin-overview`, `bootstrap-workspace`, and `sync-users`. 

---

### 4. Resources

Go to **Resources** to create application integrations, capabilities, bindings, and secrets.

#### Create application

Fields:

| Field         | Required | Meaning                                                                |
| ------------- | -------: | ---------------------------------------------------------------------- |
| Slug          |      yes | Stable application instance name, for example `nethvoice-main`.        |
| Provider type |      yes | Provider adapter family, for example `nethvoice`, `nextcloud`, `mock`. |
| Display name  |       no | Human-readable name. Defaults to slug.                                 |
| Base URL      |       no | Upstream application URL. Must be `http://` or `https://` if set.      |

The UI requires slug and provider type, and validates base URL protocol/host when provided. 

#### Create capability

Fields:

| Field         | Required | Meaning                                        |
| ------------- | -------: | ---------------------------------------------- |
| Template      |      yes | Built-in capability template.                  |
| Application   |      yes | Application instance that owns the capability. |
| Capability ID |       no | Override generated capability ID.              |
| Name          |       no | Override generated display name.               |
| Version       |       no | Capability version, default `1`.               |

Capabilities are created from templates through `create-capability-from-template`. 

#### Create binding

A binding grants one agent access to one capability for one user with one role.

Fields:

| Field      | Required |
| ---------- | -------: |
| Agent      |      yes |
| User       |      yes |
| Capability |      yes |
| Role       |      yes |

The UI calls `create-binding` after all four fields are selected. 

#### Create secret

Fields:

| Field              |    Required | Meaning                                                                              |
| ------------------ | ----------: | ------------------------------------------------------------------------------------ |
| Application        |         yes | Application instance the secret belongs to.                                          |
| Owner type         |         yes | `workspace`, `user`, or `agent`.                                                     |
| Owner              |         yes | Workspace, user, or agent that owns the secret.                                      |
| Secret type        |         yes | `api_key`, `bearer_token`, `basic_auth`, `oauth_refresh_token`, or `session_cookie`. |
| Secret value       | conditional | Plain secret value.                                                                  |
| External reference | conditional | Reference to an externally managed secret.                                           |

Exactly one of **Secret value** or **External reference** must be provided.  

#### Rotate secret

Fields:

| Field              |    Required | Meaning                                |
| ------------------ | ----------: | -------------------------------------- |
| Secret             |         yes | Existing secret to rotate.             |
| Secret type        |          no | Leave empty to keep the existing type. |
| Secret value       | conditional | New plain secret.                      |
| External reference | conditional | New external reference.                |

Exactly one of **Secret value** or **External reference** must be provided. 

#### Current resources

The page lists current:

```text
workspaces
applications
capability templates
capabilities
agents
users
roles
bindings
secrets
```

---

### 5. Agents

Go to **Agents** to create runtime clients.

#### Create agent

Fields:

| Field        | Required | Meaning                                       |
| ------------ | -------: | --------------------------------------------- |
| Slug         |      yes | Stable agent name, for example `hermes-main`. |
| Display name |       no | Human-readable name. Defaults to slug.        |
| Store token  |       no | Store generated token in a module-side file.  |

After creation, the UI shows the agent token once. Copy it immediately unless **Store token** was selected. Agent tokens are bearer credentials for runtime access. 

#### Rotate token

Select an existing agent and click **Rotate token**. The new token is shown once. Existing clients must be updated with the new token.

#### Disable agent

Click **Disable** next to an agent. The UI asks for confirmation and then calls `disable-agent`.

---

### 6. Activity

Go to **Activity** to inspect audit and usage data.

The page shows:

| Section       | Contents                                                   |
| ------------- | ---------------------------------------------------------- |
| Usage summary | Agent, user, capability, status, event count, total units. |
| Audit events  | Timestamp, actor, decision, outcome, capability.           |
| Usage events  | Timestamp, agent, user, capability, status, units.         |

The page loads data with `get-admin-overview` and requests up to 50 recent events. 

---

## Recommended first-time web workflow

```text
1. Settings
   - Set public host.
   - Enable Let’s Encrypt if the hostname is public and resolvable.
   - Select user domain if LDAP-backed users are required.
   - Enable user sync if using NS8 users.
   - Save.

2. Status
   - Verify public runtime URL.
   - Verify pod, containers, /healthz, /readyz, APISIX sync.

3. Workspace
   - Bootstrap workspace.
   - Sync users now if LDAP sync is enabled.
   - Verify roles and templates.

4. Resources
   - Create application instance.
   - Create capability from template.
   - Create or rotate required secret.
   - Create binding: agent + user + capability + role.

5. Agents
   - Create agent.
   - Copy the one-time bearer token.

6. Activity
   - Verify invocations, audit decisions, usage counters.
```

---

# Command line administration

Replace `grantora1` with the actual module instance name.

## Inspect defaults and current configuration

```bash
api-cli run module/grantora1/get-defaults
api-cli run module/grantora1/get-configuration
```

## Configure the module

```bash
api-cli run module/grantora1/configure-module --data '{
  "host": "grantora.example.org",
  "lets_encrypt": true,
  "metrics_enabled": false,
  "log_level": "INFO",
  "user_domain": "ad.example.org",
  "sync_users_enabled": true,
  "sync_users_interval_minutes": 60,
  "runtime_rate_limit_count": 1000,
  "runtime_rate_limit_time_window": 60,
  "audit_retention_days": 365,
  "usage_retention_days": 365,
  "upstream_tls_verify": true,
  "upstream_timeout_seconds": 30,
  "upstream_connect_timeout_seconds": 10,
  "upstream_max_response_bytes": 10485760,
  "upstream_read_retry_attempts": 2
}'
```

For manual users without LDAP sync:

```bash
api-cli run module/grantora1/configure-module --data '{
  "host": "grantora.example.org",
  "lets_encrypt": true,
  "metrics_enabled": false,
  "log_level": "INFO",
  "user_domain": "",
  "sync_users_enabled": false,
  "sync_users_interval_minutes": 60,
  "runtime_rate_limit_count": 1000,
  "runtime_rate_limit_time_window": 60,
  "audit_retention_days": 365,
  "usage_retention_days": 365,
  "upstream_tls_verify": true,
  "upstream_timeout_seconds": 30,
  "upstream_connect_timeout_seconds": 10,
  "upstream_max_response_bytes": 10485760,
  "upstream_read_retry_attempts": 2
}'
```

## Check status

```bash
api-cli run module/grantora1/get-status
```

On the node, as the module user:

```bash
systemctl --user status grantora.service
systemctl --user status grantora-pod.service
systemctl --user status grantora-postgres.service
systemctl --user status grantora-apisix-etcd.service
systemctl --user status grantora-api.service
systemctl --user status grantora-apisix.service
systemctl --user status grantora-user-sync.timer
systemctl --user status grantora-retention.timer

podman pod ps
podman pod port grantora
podman ps --pod
```

## Bootstrap workspace

```bash
api-cli run module/grantora1/bootstrap-workspace --data '{
  "workspace_slug": "default",
  "workspace_display_name": "Grantora Default Workspace",
  "side_effect_role_enabled": false
}'
```

With provider type:

```bash
api-cli run module/grantora1/bootstrap-workspace --data '{
  "workspace_slug": "default",
  "workspace_display_name": "Grantora Default Workspace",
  "provider_type": "nethvoice",
  "side_effect_role_enabled": false
}'
```

## List overview and templates

```bash
api-cli run module/grantora1/get-admin-overview --data '{
  "limit": 200,
  "events_limit": 25
}'

api-cli run module/grantora1/list-capability-templates --data '{}'
```

## Sync users

```bash
api-cli run module/grantora1/sync-users
```

If available from the module shell:

```bash
grantora-users status
```

## Create a manual user

Use this only when LDAP sync is disabled or when a manual user is required.

```bash
api-cli run module/grantora1/create-user --data '{
  "external_id": "alice",
  "display_name": "Alice"
}'
```

## Create an application

```bash
api-cli run module/grantora1/create-application --data '{
  "slug": "nethvoice-main",
  "display_name": "NethVoice Main",
  "provider_type": "nethvoice",
  "base_url": "https://nethvoice.example.org"
}'
```

Mock/demo example:

```bash
api-cli run module/grantora1/create-application --data '{
  "slug": "mock-phonebook",
  "display_name": "Mock Phonebook",
  "provider_type": "mock",
  "base_url": "https://mock.example.test"
}'
```

## Create a capability from template

```bash
api-cli run module/grantora1/create-capability-from-template --data '{
  "template_id": "nethvoice.phonebook.search",
  "application_instance_id": "<application-id>",
  "id": "nethvoice.phonebook.search.main",
  "name": "NethVoice phonebook search",
  "version": 1
}'
```

Mock/demo:

```bash
api-cli run module/grantora1/create-capability-from-template --data '{
  "template_id": "mock.phonebook.search",
  "application_instance_id": "<application-id>",
  "id": "mock.phonebook.search.demo",
  "name": "Mock phonebook search",
  "version": 1
}'
```

## Create an agent

```bash
api-cli run module/grantora1/create-agent --data '{
  "slug": "hermes-main",
  "display_name": "Hermes Main",
  "store_token": false
}'
```

With server-side token storage:

```bash
api-cli run module/grantora1/create-agent --data '{
  "slug": "hermes-main",
  "display_name": "Hermes Main",
  "store_token": true
}'
```

Copy the returned `agent_token`. It is needed by the runtime client.

## Rotate an agent token

```bash
api-cli run module/grantora1/rotate-agent-token --data '{
  "agent_id": "<agent-id>",
  "store_token": false
}'
```

## Disable an agent

```bash
api-cli run module/grantora1/disable-agent --data '{
  "agent_id": "<agent-id>"
}'
```

## Create a binding

```bash
api-cli run module/grantora1/create-binding --data '{
  "agent_id": "<agent-id>",
  "user_id": "<user-id>",
  "capability_id": "<capability-id>",
  "role_id": "<role-id>"
}'
```

A runtime call is allowed only when a matching active binding exists.

## Create a secret

Plain secret value:

```bash
api-cli run module/grantora1/create-secret --data '{
  "application_instance_id": "<application-id>",
  "owner_type": "user",
  "owner_id": "<user-id>",
  "secret_type": "bearer_token",
  "secret_value": "<secret>"
}'
```

External reference:

```bash
api-cli run module/grantora1/create-secret --data '{
  "application_instance_id": "<application-id>",
  "owner_type": "workspace",
  "owner_id": "<workspace-id>",
  "secret_type": "api_key",
  "external_reference": "vault://grantora/nethvoice-main/api-key"
}'
```

Allowed owner types:

```text
workspace
user
agent
```

Allowed secret types:

```text
api_key
bearer_token
basic_auth
oauth_refresh_token
session_cookie
```

## Rotate a secret

Keep existing secret type:

```bash
api-cli run module/grantora1/rotate-secret --data '{
  "secret_id": "<secret-id>",
  "secret_value": "<new-secret>"
}'
```

Change secret type:

```bash
api-cli run module/grantora1/rotate-secret --data '{
  "secret_id": "<secret-id>",
  "secret_type": "bearer_token",
  "secret_value": "<new-secret>"
}'
```

Use an external reference:

```bash
api-cli run module/grantora1/rotate-secret --data '{
  "secret_id": "<secret-id>",
  "external_reference": "vault://grantora/nethvoice-main/new-token"
}'
```

## Run retention

Dry run:

```bash
api-cli run module/grantora1/run-retention --data '{
  "dry_run": true
}'
```

Apply retention:

```bash
api-cli run module/grantora1/run-retention --data '{
  "dry_run": false
}'
```

## Run smoke checks

```bash
api-cli run module/grantora1/run-smoke
```

Run this after configuration, restore, and upgrade.

## Backup and restore

```bash
api-cli run module/grantora1/backup-module
api-cli run module/grantora1/restore-module
```

Supported restore order is:

```text
1. Restore environment and secrets.
2. Start pod.
3. Start PostgreSQL.
4. Restore PostgreSQL dump.
5. Start APISIX etcd and Grantora API.
6. Wait for readiness.
7. Start APISIX.
8. Reconcile APISIX.
9. Run smoke checks.
```

## Upgrade Grantora upstream image

Use immutable tags in production.

```bash
api-cli run module/grantora1/upgrade-module --data '{
  "grantora_version": "0.1.1",
  "grantora_image": "ghcr.io/stell0/grantora-api",
  "pull": true,
  "rollback_on_failure": true
}'
```

Do not use mutable `latest` tags for production upgrades.

---

# Runtime client usage

After creating an agent and binding it to a user/capability/role, use the returned bearer token.

```bash
export GRANTORA_URL="https://grantora.example.org"
export GRANTORA_TOKEN="<agent-token>"
```

Check agent identity:

```bash
curl -sS \
  -H "Authorization: Bearer ${GRANTORA_TOKEN}" \
  "${GRANTORA_URL}/v1/me"
```

List visible capabilities:

```bash
curl -sS \
  -H "Authorization: Bearer ${GRANTORA_TOKEN}" \
  "${GRANTORA_URL}/v1/capabilities"
```

Get filtered OpenAPI for a delegated user:

```bash
curl -sS \
  -H "Authorization: Bearer ${GRANTORA_TOKEN}" \
  "${GRANTORA_URL}/v1/capabilities/openapi.json?user=alice"
```

List MCP tools for a delegated user:

```bash
curl -sS \
  -H "Authorization: Bearer ${GRANTORA_TOKEN}" \
  "${GRANTORA_URL}/v1/mcp/tools?user=alice"
```

Invoke a capability:

```bash
curl -sS \
  -X POST \
  -H "Authorization: Bearer ${GRANTORA_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "input": {
      "query": "Mario Rossi"
    }
  }' \
  "${GRANTORA_URL}/v1/invoke/nethvoice.phonebook.search.main"
```

Check usage for the agent:

```bash
curl -sS \
  -H "Authorization: Bearer ${GRANTORA_TOKEN}" \
  "${GRANTORA_URL}/v1/usage/me"
```

---

# Operational rules

## Public/private boundaries

Do not expose these ports or paths through Traefik:

```text
Grantora Admin API: /v1/admin/*
Grantora health/readiness: /healthz, /readyz
Grantora metrics: /metrics
APISIX Admin API: 9180
PostgreSQL: 5432
APISIX etcd: 2379
```

Only runtime `/v1/*` endpoints are public to authenticated agents.

## Token handling

```text
- Agent tokens are bearer credentials.
- The UI shows new or rotated tokens once.
- Store them in the consuming agent secret store.
- Rotate tokens when an agent is retired or compromised.
- Disable unused agents.
```

## Secret handling

```text
- Store provider credentials as Grantora secrets.
- Do not put provider credentials in prompts, bindings, agent config, or runtime payloads.
- Prefer user-owned secrets for delegated user operations.
- Prefer workspace-owned secrets only for shared service credentials.
- Rotate provider secrets through Resources -> Rotate secret or rotate-secret action.
```

## LDAP/user sync behavior

```text
- Selected NS8 user domain is configured in Settings.
- LDAP usernames become Grantora external IDs.
- Hidden or locked users are not imported.
- Removed users can be disabled by later syncs.
- LDAP passwords are not stored or passed to agents.
```

## Troubleshooting

### Public URL does not work

Check:

```bash
api-cli run module/grantora1/get-status
api-cli run module/grantora1/get-configuration
```

Verify:

```text
- Host is a valid FQDN.
- DNS points to the NS8 node.
- Let’s Encrypt is enabled only when public DNS is valid.
- Status shows APISIX sync successful.
- Runtime URL is shown in Status.
```

### Agent receives 401/403

Check:

```text
- Correct bearer token.
- Agent is active.
- User exists and is active.
- Capability exists and is active.
- Binding exists for agent + user + capability + role.
- Secret exists with the expected owner/type.
```

Use:

```bash
api-cli run module/grantora1/get-admin-overview --data '{
  "limit": 200,
  "events_limit": 50
}'
```

Then inspect **Activity** for denied audit events.

### LDAP users are missing

Check:

```bash
api-cli run module/grantora1/get-configuration
api-cli run module/grantora1/sync-users
api-cli run module/grantora1/get-status
```

Verify:

```text
- User domain is selected.
- Sync users is enabled.
- Domain is reachable.
- User is not hidden or locked.
```

### Provider invocation fails

Check:

```text
- Application base URL is reachable from the Grantora container.
- Upstream TLS verification is compatible with the provider certificate.
- Correct secret type and owner are used.
- Capability template matches provider type.
- Upstream timeout and max response size are sufficient.
```

Review **Activity** for audit/usage status and provider-safe errors.

### Containers or units are not running

On the node as the module user:

```bash
systemctl --user status grantora.service
systemctl --user status grantora-api.service
systemctl --user status grantora-apisix.service
systemctl --user status grantora-postgres.service
systemctl --user status grantora-apisix-etcd.service

journalctl --user -u grantora.service -n 200 --no-pager
journalctl --user -u grantora-api.service -n 200 --no-pager
journalctl --user -u grantora-apisix.service -n 200 --no-pager
```

If available:

```bash
grantora-operations logs grantora-api.service --lines 200
grantora-operations logs grantora-apisix.service --lines 200
grantora-pod-exec metrics
```

---

# Minimal production checklist

```text
[ ] Public FQDN configured.
[ ] Let’s Encrypt enabled and certificate valid.
[ ] Status page shows healthy pod, containers, /healthz, /readyz.
[ ] APISIX sync successful.
[ ] Workspace bootstrapped.
[ ] LDAP user sync configured or manual users created.
[ ] Application instances created.
[ ] Capabilities created from templates.
[ ] Provider secrets created with correct owner/type.
[ ] Agents created and tokens stored securely.
[ ] Bindings created for each allowed agent/user/capability/role combination.
[ ] Activity page reviewed after first runtime invocation.
[ ] Retention policy configured.
[ ] Backup tested.
[ ] Smoke checks pass after configuration and upgrades.
```
