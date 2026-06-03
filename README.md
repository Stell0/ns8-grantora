# ns8-grantora

`ns8-grantora` packages the Grantora Agent Capability Gateway for NethServer 8 without forking upstream Grantora application logic.

The module runs Grantora as one rootless Podman pod, exposes only the APISIX runtime gateway through Traefik, keeps Grantora Admin API and infrastructure ports private, and gives cluster administrators both UI pages and NS8 actions for installation, user sync, bootstrap, backup, restore, upgrade, and day-2 operations.

## What This Module Deploys

- One rootless Podman pod named `grantora`.
- One public Traefik route to APISIX runtime only.
- One private Grantora Admin API reachable only from inside the pod.
- Separate user systemd units for pod, PostgreSQL, APISIX etcd, Grantora API, APISIX, user sync, and retention.
- NS8 UI pages for Status, Settings, Workspace, Agents, Applications, and Activity.
- NS8 actions for bootstrap, user sync, secret management, retention, smoke, backup, restore, and upgrade.

Grantora remains the upstream application of record. Dynamic state stays in PostgreSQL, APISIX etcd remains generated runtime state, and the NS8 module owns generated environment files, secrets, routes, timers, and lifecycle automation.

## Install

### Install from a published image

Build and publish the module image, or use a released module image tag:

```bash
./build-images.sh
add-module ghcr.io/stell0/grantora:<module-tag> 1
```

## Topology And Exposure

Runtime flow:

```text
Agent or automation client
	-> NS8 Traefik public route
	-> 127.0.0.1:<TCP_PORT>
	-> grantora Podman pod
	-> APISIX runtime port 9080
	-> Grantora API internal port 8080
	-> PostgreSQL internal port 5432
```

Systemd user units:

```text
grantora.service
grantora-pod.service
grantora-postgres.service
grantora-apisix-etcd.service
grantora-api.service
grantora-apisix.service
grantora-user-sync.timer
grantora-user-sync.service
grantora-retention.timer
grantora-retention.service
```

Only `grantora-pod.service` publishes a host port, and it publishes only `127.0.0.1:${TCP_PORT}:9080`.

### Public and private surfaces

| Surface | Location | Exposure | Access path |
| --- | --- | --- | --- |
| Runtime API | `https://<host>/v1/*` | Public to authenticated agents | Traefik -> APISIX |
| Static runtime OpenAPI | `GET /v1/openapi.json` | Public runtime contract | APISIX |
| Filtered capability OpenAPI | `GET /v1/capabilities/openapi.json?user=<external_id>` | Public to authenticated agents | APISIX |
| MCP tool discovery | `GET /v1/mcp/tools?user=<external_id>` | Public to authenticated agents | APISIX |
| MCP tool call | `POST /v1/mcp/call` | Public to authenticated agents | APISIX |
| Grantora Admin API | `http://127.0.0.1:8080/v1/admin/*` | Private | `grantora-admin` or `grantora-pod-exec` |
| Health and readiness | `http://127.0.0.1:8080/healthz`, `readyz` | Private | `get-status`, `grantora-pod-exec` |
| Metrics | `http://127.0.0.1:8080/metrics` | Private | `grantora-pod-exec metrics` |
| APISIX Admin API | `http://127.0.0.1:9180` | Private | Pod-local only |
| PostgreSQL | `127.0.0.1:5432` inside pod | Private | Pod-local only |
| APISIX etcd | `127.0.0.1:2379` inside pod | Private | Pod-local only |

Do not add Traefik routes or host port mappings for `8080`, `9180`, `5432`, or `2379`. Grantora runtime endpoints are public to agents by design. Admin and operator surfaces stay pod-local.

## First-Time Configuration

The recommended operator flow uses the UI first and CLI actions second.

### UI flow

1. Open the Grantora module in cluster-admin.
2. In `Settings`, configure the public hostname, runtime image settings, user provider, runtime policy, and upstream defaults.
3. Save the configuration.
4. In `Status`, verify pod state, systemd units, `/healthz`, `/readyz`, APISIX sync, and public runtime URL.
5. In `Workspace`, run `Bootstrap workspace`, then `Sync users now` if LDAP sync is enabled.
6. In `Applications`, create application instances, capabilities, bindings, and secrets.
7. In `Agents`, create an agent and capture the one-time token if you need a runtime client.
8. In `Activity`, review audit events and usage summaries.

UI pages map directly to NS8 actions. The UI does not talk to Grantora Admin API over a public route.

### CLI flow

Query defaults first:

```bash
api-cli run module/grantora1/get-defaults
api-cli run module/grantora1/get-configuration
```

Then configure the instance:

```bash
api-cli run module/grantora1/configure-module --data '{
	"host": "grantora.example.org",
	"lets_encrypt": true,
	"user_domain": "ad.example.org",
	"sync_users_enabled": true,
	"sync_users_interval_minutes": 60,
	"grantora_image": "ghcr.io/grantora/grantora-api",
	"grantora_version": "0.1.0",
	"metrics_enabled": true,
	"log_level": "INFO",
	"runtime_rate_limit_count": 1000,
	"runtime_rate_limit_time_window": 60,
	"audit_retention_days": 365,
	"usage_retention_days": 365,
	"upstream_tls_verify": true,
	"upstream_timeout_seconds": 30,
	"upstream_connect_timeout_seconds": 10,
	"upstream_max_response_bytes": 1048576,
	"upstream_read_retry_attempts": 2
}'
```

`configure-module` renders generated env files under `state/`, preserves previously generated secrets, starts `grantora.service`, creates the Traefik route, and triggers APISIX sync through the private Admin API helper.

### Configuration fields

Use `get-defaults` or the `Settings` page as the source of current defaults. The main fields are:

| Field | Meaning | Notes |
| --- | --- | --- |
| `host` | Public FQDN for agents | Required. Must be a fully qualified hostname. |
| `lets_encrypt` | NS8 certificate request | Controls Traefik certificate automation. |
| `tcp_port` | Loopback APISIX runtime port | Must not be `2379`, `5432`, `8080`, or `9180`. |
| `grantora_image` | Upstream Grantora API image | Use a stable registry and immutable tags for production. |
| `grantora_version` | Upstream Grantora version tag | Used by upgrade and status reporting. |
| `log_level` | Grantora application log level | `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`. |
| `metrics_enabled` | Private metrics endpoint toggle | Keeps metrics pod-local. |
| `user_domain` | Selected NS8 account provider | Enables managed LDAP user sync when present. |
| `sync_users_enabled` | LDAP sync toggle | When disabled, users are managed manually in Grantora. |
| `sync_users_interval_minutes` | Periodic LDAP sync interval | Drives `grantora-user-sync.timer`. |
| `runtime_rate_limit_count` | APISIX runtime limit count | Applies to public runtime traffic. |
| `runtime_rate_limit_time_window` | APISIX rate-limit window in seconds | Pairs with runtime rate limit count. |
| `audit_retention_days` | Audit data retention window | Used by the retention timer and manual retention action. |
| `usage_retention_days` | Usage data retention window | Used by the retention timer and manual retention action. |
| `upstream_tls_verify` | TLS verification for provider calls | Keep enabled unless the upstream deployment requires an explicit exception. |
| `upstream_timeout_seconds` | Total upstream request timeout | Bounded to avoid hanging adapters. |
| `upstream_connect_timeout_seconds` | Upstream connect timeout | Separate connect timeout for slower networks. |
| `upstream_max_response_bytes` | Maximum upstream payload size | Prevents oversized responses from reaching adapters. |
| `upstream_read_retry_attempts` | Retry count for read-only upstream operations | Use low values only for idempotent reads. |

## Selected User Provider Behavior

The module is an NS8 account-domain consumer. User provider handling is owned by NS8, not by Grantora.

- `get-configuration` and the `Settings` page list available user domains, including schema, provider module, and reachability.
- The selected domain is bound to the module during configuration.
- LDAP usernames are synced into Grantora as `external_id` values.
- Hidden or locked LDAP users are not imported.
- Previously managed users that disappear from the selected domain can be disabled on later syncs.
- LDAP passwords are never stored in Grantora and are never passed to agents.
- If no suitable domain is available, leave sync disabled and create Grantora users explicitly.

Useful commands:

```bash
api-cli run module/grantora1/get-configuration
api-cli run module/grantora1/sync-users
grantora-users status
```

## Workspace Bootstrap And Day-2 Operations

Bootstrap the default workspace and roles:

```bash
api-cli run module/grantora1/bootstrap-workspace --data '{}'
api-cli run module/grantora1/list-capability-templates --data '{}'
```

Inspect status without opening a shell in the containers:

```bash
api-cli run module/grantora1/get-status
systemctl --user status grantora.service
systemctl --user status grantora-api.service
podman pod port grantora
```

Read redacted logs and private metrics:

```bash
grantora-operations logs grantora-api.service --lines 200
grantora-operations logs grantora-apisix.service --lines 200
grantora-pod-exec metrics
```

Run retention safely:

```bash
api-cli run module/grantora1/run-retention --data '{"dry_run":true}'
api-cli run module/grantora1/run-retention --data '{"dry_run":false}'
systemctl --user status grantora-retention.timer
```

Run smoke checks after configure, restore, or upgrade:

```bash
api-cli run module/grantora1/run-smoke
```

## Backup, Restore, And Upgrade

### Backup and restore order

`backup-module` and `restore-module` are the supported NS8 lifecycle actions. The restore flow is intentionally ordered to keep Admin, database, and APISIX control surfaces private throughout recovery.

Restore sequence:

1. Restore generated env files and module secrets first.
2. Start `grantora-pod.service`.
3. Start `grantora-postgres.service`.
4. Restore the PostgreSQL dump through the private pod helper.
5. Start `grantora-apisix-etcd.service` and `grantora-api.service`.
6. Wait for `/readyz` through the private helper.
7. Start `grantora-apisix.service`.
8. Run APISIX sync through `grantora-admin`.
9. Run `run-smoke`.

Operator commands:

```bash
api-cli run module/grantora1/backup-module
api-cli run module/grantora1/restore-module
```

### Upgrade procedure

Upgrade the upstream Grantora API image with `upgrade-module`. Use immutable image tags and explicit versions. The action can optionally pull the image and roll back on failure.

```bash
api-cli run module/grantora1/upgrade-module --data '{
	"grantora_version": "0.1.1",
	"grantora_image": "ghcr.io/grantora/grantora-api",
	"pull": true,
	"rollback_on_failure": true
}'
```

Upgrade behavior:

1. Record current version and runtime state.
2. Back up PostgreSQL and preserve existing env secrets.
3. Pull the requested image when `pull=true`.
4. Restart the Grantora API container with the new image.
5. Run upstream migrations when the image provides them.
6. Wait for `/readyz`.
7. Reconcile APISIX.
8. Run smoke checks.
9. Preserve the pre-upgrade backup if the upgrade fails.

Do not use mutable `latest`-style runtime tags for production upgrades.

## Provider Setup Examples

Start by listing the built-in templates:

```bash
api-cli run module/grantora1/list-capability-templates --data '{}'
```

### Mock or demo capability

This is the quickest end-to-end validation path.

```bash
api-cli run module/grantora1/bootstrap-workspace --data '{}'
api-cli run module/grantora1/create-application --data '{"workspace_id":"<workspace-id>","slug":"mock-phonebook","display_name":"Mock Phonebook","provider_type":"mock","base_url":"https://mock.example.test"}'
api-cli run module/grantora1/create-user --data '{"workspace_id":"<workspace-id>","external_id":"alice","display_name":"Alice"}'
api-cli run module/grantora1/create-capability-from-template --data '{"workspace_id":"<workspace-id>","template_id":"mock.phonebook.search","application_instance_id":"<application-id>","id":"mock.phonebook.search.demo","name":"Mock phonebook search"}'
api-cli run module/grantora1/create-agent --data '{"workspace_id":"<workspace-id>","slug":"demo-agent","display_name":"Demo Agent","store_token":false}'
api-cli run module/grantora1/create-binding --data '{"workspace_id":"<workspace-id>","agent_id":"<agent-id>","user_id":"<user-id>","capability_id":"mock.phonebook.search.demo","role_id":"<read-only-role-id>"}'
```

Then invoke the runtime path with the one-time agent token returned by `create-agent`:

```bash
curl -sS -X POST https://grantora.example.org/v1/invoke/mock.phonebook.search.demo \
	-H 'Authorization: Bearer <agent-token>' \
	-H 'Content-Type: application/json' \
	-d '{"user":"alice","input":{"query":"Mario","limit":5}}'
```

### NethVoice phonebook search

Use the built-in `nethvoice.phonebook.search` template with a delegated read-only credential.

```bash
api-cli run module/grantora1/create-application --data '{"workspace_id":"<workspace-id>","slug":"nethvoice","display_name":"NethVoice","provider_type":"nethvoice","base_url":"https://pbx.example.org"}'
api-cli run module/grantora1/create-capability-from-template --data '{"workspace_id":"<workspace-id>","template_id":"nethvoice.phonebook.search","application_instance_id":"<application-id>","id":"nethvoice.phonebook.search.office","name":"NethVoice phonebook search"}'
api-cli run module/grantora1/create-secret --data '{"workspace_id":"<workspace-id>","application_instance_id":"<application-id>","owner_type":"workspace","owner_id":"<workspace-id>","secret_type":"bearer_token","secret_value":"<delegated-nethvoice-token>"}'
```

Use a token with phonebook read access only. Store it as a Grantora secret, not in the agent definition, binding, prompt, or capability input.

### Nextcloud files search

Use the built-in `nextcloud.files.search` template with a delegated app password or supported bearer token.

```bash
api-cli run module/grantora1/create-application --data '{"workspace_id":"<workspace-id>","slug":"nextcloud","display_name":"Nextcloud","provider_type":"nextcloud","base_url":"https://cloud.example.org"}'
api-cli run module/grantora1/create-capability-from-template --data '{"workspace_id":"<workspace-id>","template_id":"nextcloud.files.search","application_instance_id":"<application-id>","id":"nextcloud.files.search.docs","name":"Nextcloud files search"}'
api-cli run module/grantora1/create-secret --data '{"workspace_id":"<workspace-id>","application_instance_id":"<application-id>","owner_type":"workspace","owner_id":"<workspace-id>","secret_type":"basic_auth","secret_value":"alice:app-password"}'
```

Use a delegated credential with file read and search access only. For workspace-scoped provider credentials, `owner_type=workspace` requires `owner_id` to match the workspace id.

## Safe Secret Handling

Provider secrets and agent tokens are different things.

- Upstream provider secrets belong in Grantora secret records created through `create-secret` or the `Applications` UI page.
- Agent bearer tokens are generated only by `create-agent` and `rotate-agent-token`.
- Exactly one of `secret_value` or `external_reference` must be provided when creating or rotating a secret.
- `secret_value` is redacted by NS8 task handling because the input key contains `secret`.
- Use `external_reference` when you have an external secret store integration and do not want the secret payload stored inside Grantora.
- Prefer workspace-scoped secrets for shared provider credentials and user-scoped secrets for per-user delegated credentials.
- Never paste upstream provider secrets into agent prompts, bindings, capability ids, or runtime API calls.

Rotate a stored provider secret with:

```bash
api-cli run module/grantora1/rotate-secret --data '{"secret_id":"<secret-id>","secret_value":"<new-secret-value>"}'
```

## Agent Integration

The agent runtime bearer token returned by `create-agent` or `rotate-agent-token` is the only credential an external agent needs for public runtime access.

Available runtime discovery surfaces:

- `GET /v1/openapi.json` returns the static runtime API contract.
- `GET /v1/capabilities/openapi.json?user=<external_id>` returns a filtered OpenAPI document for the selected user.
- `GET /v1/mcp/tools?user=<external_id>` returns an MCP-compatible tool list for the selected user.
- `POST /v1/mcp/call` executes a tool call mapped back to the same runtime capability executor.

Filtered OpenAPI and MCP tools are generated from the same allowed capability set. An agent only sees capabilities it is allowed to describe and invoke for the selected user.

Example with the demo agent token:

```bash
curl -sS 'https://grantora.example.org/v1/mcp/tools?user=alice' \
	-H 'Authorization: Bearer <agent-token>'

curl -sS -X POST https://grantora.example.org/v1/mcp/call \
	-H 'Authorization: Bearer <agent-token>' \
	-H 'Content-Type: application/json' \
	-d '{"user":"alice","name":"mock_phonebook_search","arguments":{"query":"Mario","limit":5}}'

curl -sS 'https://grantora.example.org/v1/capabilities/openapi.json?user=alice' \
	-H 'Authorization: Bearer <agent-token>'
```

Agents should never call `/v1/admin/*`, `/healthz`, `/readyz`, `/metrics`, the APISIX Admin API, PostgreSQL, or etcd. Those are operator-only private surfaces.

## Troubleshooting

Common operator commands:

```bash
# Global status
api-cli run module/grantora1/get-status

# APISIX sync state
grantora-admin GET /v1/admin/apisix/status
grantora-admin POST /v1/admin/apisix/sync

# PostgreSQL readiness
systemctl --user status grantora-postgres.service
grantora-pod-exec exec grantora-postgres pg_isready -U grantora -d grantora

# User sync failures
api-cli run module/grantora1/sync-users
grantora-users status
grantora-operations logs grantora-user-sync.service --lines 200

# Runtime/API failures
grantora-operations logs grantora-api.service --lines 200
grantora-operations logs grantora-apisix.service --lines 200
```

## Unsupported Features And Future Work

The current module intentionally does not provide or expose the following:

- No public Grantora Admin API route.
- No public APISIX Admin API, PostgreSQL, or etcd exposure.
- No public metrics endpoint.
- No default host-mapped admin port.
- No encryption-key rotation until upstream re-encryption support exists.
- No token-pepper rotation until upstream token migration support exists.
- No operator OIDC or trusted-proxy admin identity enabled by default.

Upstream work still matters for production readiness:

- Versioned production database migrations are still required upstream.
- Immutable upstream release images should be used for production module releases.
- A bulk and idempotent upstream user sync API would simplify large-domain imports.
- Software Center metadata publication may lag behind image publication.

## Tests

This repository uses the NS8 testing infrastructure. For local execution guidance, refer to the [ns8-github-actions test README](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally).

Local static and packaging gates:

```bash
python3 tests/action_contracts.py
python3 tests/systemd_contracts.py
python3 tests/security_static.py
NODE_OPTIONS=--openssl-legacy-provider corepack yarn --cwd ui build
```

The Robot suite in [tests/grantora.robot](tests/grantora.robot) covers install, configure, status, public runtime route, private-surface denials, user sync, demo capability creation and invocation, backup, restore, same-version upgrade smoke, authorization denials, and destroy against a real NS8 test node.

## Uninstall

```bash
remove-module --no-preserve grantora1
```
