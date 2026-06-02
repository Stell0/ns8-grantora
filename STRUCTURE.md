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
- `actions/sync-users/`: syncs the selected NS8 user domain into Grantora users through pod-local Admin API calls.
- `actions/bootstrap-workspace/`: creates or reuses the default Grantora workspace, seeds default runtime roles, lists templates, and records ids in `state/bootstrap.json`.
- `actions/list-capability-templates/`: lists upstream built-in capability templates through the pod-local Admin API.
- `actions/create-application/`, `actions/create-user/`, `actions/create-role/`, `actions/create-capability-from-template/`, `actions/create-binding/`: idempotent helper actions for common Grantora object setup.
- `actions/create-secret/` and `actions/rotate-secret/`: create and rotate upstream provider secrets without exposing secret values in persisted bootstrap state.
- `actions/create-agent/` and `actions/rotate-agent-token/`: create agents and return one-time plaintext tokens only in the action response, with optional explicit storage under `state/agent-tokens/`.
- `actions/destroy-module/`: stops the aggregate service and helper units.
- `bin/grantora-env`: idempotent state, secret, and env-file renderer for the runtime skeleton.
- `bin/grantora-admin`: pod-local Grantora Admin API caller that reads admin bootstrap credentials from `state/secrets.env`.
- `bin/grantora-bootstrap`: idempotent bootstrap/admin helper used by Milestone 4 actions.
- `bin/grantora-pod-exec`: safe pod-local health/status/API helper with allowlisted container exec fallback.
- `bin/grantora-users`: NS8 account-domain discovery, binding, sync and sync-status helper.
- `systemd/user/grantora.service`: aggregate Grantora service.
- `systemd/user/grantora-pod.service`: owns pod `grantora` and the only host port mapping, `127.0.0.1:${TCP_PORT}:9080`.
- `systemd/user/grantora-postgres.service`: PostgreSQL helper container in the pod.
- `systemd/user/grantora-apisix-etcd.service`: APISIX etcd helper container in the pod.
- `systemd/user/grantora-api.service`: upstream Grantora API container in the pod.
- `systemd/user/grantora-apisix.service`: APISIX runtime/data-plane container in the pod.
- `systemd/user/grantora-user-sync.timer` and `grantora-user-sync.service`: periodic LDAP user sync.

## Target expansion

Later milestones add backup/restore, upgrades, and the admin UI surfaces tracked in [PLAN.md](PLAN.md).
