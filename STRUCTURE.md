# STRUCTURE.md

Current repository map for `ns8-grantora` during repository initialization.

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

- `actions/configure-module/`: placeholder configure action kept stable for Milestone 0.
- `actions/get-configuration/`: returns current module configuration shape.
- `actions/destroy-module/`: tears down Milestone 0 placeholder state.
- `systemd/user/grantora.service`: temporary placeholder unit that will become the aggregate Grantora service in Milestone 1.

## Target expansion

Later milestones add the explicit Grantora pod topology under `imageroot/systemd/user/` and more actions such as `get-status`, `sync-users`, `backup-module`, and `restore-module`. The planned layout is tracked in [PLAN.md](PLAN.md).
