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
- `actions/destroy-module/`: stops the aggregate service and helper units.
- `bin/grantora-env`: idempotent state, secret, and env-file renderer for the runtime skeleton.
- `systemd/user/grantora.service`: aggregate Grantora service.
- `systemd/user/grantora-pod.service`: owns pod `grantora` and the only host port mapping, `127.0.0.1:${TCP_PORT}:9080`.
- `systemd/user/grantora-postgres.service`: PostgreSQL helper container in the pod.
- `systemd/user/grantora-apisix-etcd.service`: APISIX etcd helper container in the pod.
- `systemd/user/grantora-api.service`: upstream Grantora API container in the pod.
- `systemd/user/grantora-apisix.service`: APISIX runtime/data-plane container in the pod.

## Target expansion

Later milestones add public Traefik routing, richer status actions, user-domain sync, bootstrap helpers, backup/restore, and the admin UI surfaces tracked in [PLAN.md](PLAN.md).
