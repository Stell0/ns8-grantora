# ns8-grantora

`ns8-grantora` packages the Grantora Agent Capability Gateway for NethServer 8 without forking upstream Grantora application logic.

Milestone 4 adds the first bootstrap/admin helper flow described in [PLAN.md](PLAN.md). The module starts Grantora as one rootless Podman pod with helper containers managed by separate user systemd units, publishes only the APISIX runtime port on loopback, creates the public Traefik route to that runtime gateway, and provides NS8 actions for common Grantora Admin API setup.

## Current scope

- Repository identity is `ns8-grantora` across docs, tests, UI metadata, and image build output.
- The module image reserves one TCP port for the APISIX runtime route.
- NS8 authorizations are prepared for Traefik route management and account-domain consumption.
- The runtime skeleton creates one Podman pod named `grantora` and publishes only `127.0.0.1:${TCP_PORT}:9080`.
- PostgreSQL, APISIX etcd, Grantora API, and APISIX each have their own inspectable user service.
- Generated env files and module secrets are rendered under `state/`; secret-bearing files are written with mode `0600`.
- `configure-module` configures a Traefik route from `https://<host>/` to `http://127.0.0.1:${TCP_PORT}`.
- `grantora-admin` calls private Grantora Admin API endpoints from inside the pod, including APISIX reconciliation.
- `run-smoke` verifies private runtime paths, loopback-only pod port publishing, and `0600` modes on secret-bearing state files.
- `grantora-pod-exec` exposes safe pod-local health/status/Admin API calls with an allowlisted container exec fallback.
- `bootstrap-workspace` creates or reuses the default workspace, seeds default runtime permissions/roles, lists built-in capability templates, and records ids in `state/bootstrap.json`.
- Helper actions create applications, users, roles, capabilities from templates, agents, bindings, and secrets through pod-local Admin API calls.
- One-time agent tokens are returned only by explicit create/rotate actions and are stored under `state/agent-tokens/` only when `store_token` is requested.
- `get-defaults`, `get-configuration`, and `get-status` expose the initial operator-facing action contract.
- CI validates markdown, shell scripts, Python action helpers, and action schema JSON.

## Install

Build the module image locally:

```bash
./build-images.sh
```

Then instantiate the module with the image you published, for example:

```bash
add-module ghcr.io/nethserver/grantora:latest 1
```

The command returns the instance name, for example:

```json
{"module_id": "grantora1", "image_name": "grantora", "image_url": "ghcr.io/nethserver/grantora:latest"}
```

## Configure

`configure-module` renders state/env files, starts the runtime services, configures the public APISIX runtime route, and reconciles APISIX through the pod-local Grantora Admin API.

```bash
api-cli run module/grantora1/configure-module --data '{"host":"grantora.example.org","lets_encrypt":false}'
```

The action starts `grantora.service`, which pulls and runs the configured upstream Grantora, PostgreSQL, APISIX etcd, and APISIX images. The only host port mapping is the loopback APISIX runtime port owned by `grantora-pod.service`; Grantora Admin API, APISIX Admin API, PostgreSQL, and etcd stay private inside the pod.

The selected runtime port cannot be one of the pod-local service ports `2379`, `5432`, `8080`, or `9180`. Application upstream `base_url` values entered through actions or the UI must be absolute `http` or `https` URLs; upstream Grantora performs origin safety validation before adapters use those URLs.

Query defaults and status:

```bash
api-cli run module/grantora1/get-defaults
api-cli run module/grantora1/get-configuration
api-cli run module/grantora1/get-status
```

## Bootstrap

Create or reuse the default workspace and runtime roles:

```bash
api-cli run module/grantora1/bootstrap-workspace --data '{}'
```

Common provider setup actions are exposed as NS8 actions and call Grantora only from inside the pod:

```bash
api-cli run module/grantora1/list-capability-templates --data '{}'
api-cli run module/grantora1/create-application --data '{"slug":"nextcloud","provider_type":"nextcloud","base_url":"https://nextcloud.example.org"}'
api-cli run module/grantora1/create-capability-from-template --data '{"template_id":"nextcloud.files.search","application_instance_id":"<application-id>"}'
api-cli run module/grantora1/create-agent --data '{"slug":"automation-agent","store_token":false}'
api-cli run module/grantora1/create-binding --data '{"agent_id":"<agent-id>","user_id":"<user-id>","capability_id":"nextcloud.files.search","role_id":"<role-id>"}'
```

Secret actions use `secret_value` so NS8 task-context redaction can apply to sensitive input:

```bash
api-cli run module/grantora1/create-secret --data '{"application_instance_id":"<application-id>","owner_type":"user","owner_id":"<user-id>","secret_type":"bearer_token","secret_value":"<token>"}'
api-cli run module/grantora1/rotate-secret --data '{"secret_id":"<secret-id>","secret_value":"<new-token>"}'
```

Useful service checks on the module instance:

```bash
systemctl --user status grantora.service
systemctl --user status grantora-postgres.service
systemctl --user status grantora-apisix-etcd.service
systemctl --user status grantora-api.service
systemctl --user status grantora-apisix.service
podman pod port grantora
```

Run the module smoke and security checks after configure, restore, or upgrade:

```bash
api-cli run module/grantora1/run-smoke
```

## Roadmap

- Backup/restore, upgrades, and the admin UI are tracked in [PLAN.md](PLAN.md) as later milestones.

## Tests

This repository uses the NS8 testing infrastructure. For local execution guidance, refer to the [ns8-github-actions test README](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally).

## Uninstall

```bash
remove-module --no-preserve grantora1
```
