# STRUCTURE.md

Current repository map for `ns8-grantora` during the pod-based runtime packaging skeleton.

## Root

- `README.md`: operator-facing status and milestone guidance.
- `AGENTS.md`: NS8 working rules plus Grantora-specific exposure boundaries.
- `PLAN.md`: milestone roadmap and target runtime topology.
- `build-images.sh`: module image build and NS8 image labels.
- `imageroot/`: NS8 module payload copied into the installed environment.
- `tests/`: Robot lifecycle coverage for the current milestone.
- `ui/`: cluster-admin module UI and metadata.
- `.github/`: CI workflows for linting, image publication, and module tests.

## `imageroot/`

- `actions/configure-module/`: renders runtime state/env files and restarts `grantora.service`.
- `actions/get-configuration/`: returns safe runtime skeleton configuration and generated-file presence.
- `actions/get-admin-overview/`: returns safe Admin API metadata, audit events and usage summaries through pod-local Admin API access for the module UI.
- `actions/backup-module/`: creates the logical PostgreSQL backup dump used by NS8 backup/restore.
- `actions/restore-module/`: restores generated env/secret state, PostgreSQL data, route/user-domain bindings, APISIX reconciliation and smoke checks without exposing private services.
- `actions/run-smoke/`: executes pod-local health, readiness, APISIX sync and runtime route/discovery checks.
- `actions/run-retention/`: dry-runs or applies upstream audit/usage retention through the private Grantora API container.
- `actions/upgrade-module/`: performs a safe upstream Grantora image/version upgrade with pre-upgrade dump, status/image snapshots, APISIX sync, smoke checks and safe failure records.
- `actions/rotate-module-secrets/`: rotates safe module-level secrets and refuses unsupported pepper/encryption-key rotation until upstream support exists.
- `actions/sync-users/`: syncs the selected NS8 user domain into Grantora users through pod-local Admin API calls.
- `actions/bootstrap-workspace/`: creates or reuses the default Grantora workspace, seeds default runtime roles, lists templates, and records ids in `state/bootstrap.json`.
- `actions/list-capability-templates/`: lists upstream built-in capability templates through the pod-local Admin API.
- `actions/create-application/`, `actions/create-user/`, `actions/create-role/`, `actions/create-capability-from-template/`, `actions/create-binding/`: idempotent helper actions for common Grantora object setup.
- `actions/create-secret/` and `actions/rotate-secret/`: create and rotate upstream provider secrets without exposing secret values in persisted bootstrap state.
- `actions/create-agent/`, `actions/rotate-agent-token/` and `actions/disable-agent/`: create, rotate and disable agents; plaintext tokens are returned only in the action response, with optional explicit storage under `state/agent-tokens/`.
- `actions/destroy-module/`: stops the aggregate service and helper units.
- `bin/grantora-env`: idempotent state, secret, and env-file renderer for the runtime skeleton.
- `bin/grantora-admin`: pod-local Grantora Admin API caller that reads admin bootstrap credentials from `state/secrets.env`.
- `bin/grantora-bootstrap`: idempotent bootstrap/admin helper used by workspace, object, overview and agent lifecycle actions.
- `bin/grantora-lifecycle`: safe upgrade and module-secret rotation helper used by lifecycle actions.
- `bin/grantora-operations`: redacted operator helper for allowlisted journal logs, private metrics, and retention execution.
- `bin/grantora-pg-dump` and `bin/grantora-pg-restore`: PostgreSQL custom-format dump/restore helpers executed through the private pod-local PostgreSQL container.
- `bin/grantora-pod-exec`: safe pod-local health/status/API helper with allowlisted container exec fallback.
- `bin/grantora-smoke`: pod-local smoke helper used by restore and the `run-smoke` action.
- `bin/grantora-users`: NS8 account-domain discovery, binding, sync and sync-status helper.
- `bin/module-dump-state` and `bin/module-cleanup-state`: NS8 backup hooks that create and clean the PostgreSQL dump around module state backup.
- `etc/state-include.conf` and `etc/state-exclude.conf`: backup manifests for generated env/secrets/bootstrap/user-domain/lifecycle/explicit token state and exclusions for transient/generated data.
- `systemd/user/grantora.service`: aggregate Grantora service.
- `systemd/user/grantora-pod.service`: owns pod `grantora` and the only host port mapping, `127.0.0.1:${TCP_PORT}:9080`.
- `systemd/user/grantora-postgres.service`: PostgreSQL helper container in the pod.
- `systemd/user/grantora-apisix-etcd.service`: APISIX etcd helper container in the pod.
- `systemd/user/grantora-api.service`: upstream Grantora API container in the pod.
- `systemd/user/grantora-apisix.service`: APISIX runtime/data-plane container in the pod.
- `systemd/user/grantora-user-sync.timer` and `grantora-user-sync.service`: periodic LDAP user sync.
- `systemd/user/grantora-retention.timer` and `grantora-retention.service`: periodic audit/usage retention through the upstream CLI.

## Target expansion

Later milestones add upgrades and broader lifecycle/testing surfaces tracked in [PLAN.md](PLAN.md).
