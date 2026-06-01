# ns8-grantora

`ns8-grantora` packages the Grantora Agent Capability Gateway for NethServer 8 without forking upstream Grantora application logic.

Milestone 0 initializes the repository identity and CI surfaces. It does not yet ship the production Grantora pod topology described in [PLAN.md](PLAN.md).

## Current scope

- Repository identity is `ns8-grantora` across docs, tests, UI metadata, and image build output.
- The module image reserves one TCP port for the future APISIX runtime route.
- NS8 authorizations are prepared for Traefik route management and account-domain consumption.
- Template `smarthost` and fake echo-server scaffolding have been removed.
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

At this milestone `configure-module` is intentionally a no-op placeholder while the runtime packaging work lands in Milestone 1 and Milestone 2.

```bash
api-cli run module/grantora1/configure-module --data '{}'
```

The action succeeds so the repository can be exercised in NS8, but it does not yet start the Grantora runtime stack or publish a route.

## Roadmap

- Podman pod packaging for Grantora, PostgreSQL, APISIX, and etcd begins in [PLAN.md](PLAN.md).
- Public runtime routing, status reporting, user-domain binding, and backup/restore are tracked there as later milestones.

## Tests

This repository uses the NS8 testing infrastructure. For local execution guidance, refer to the [ns8-github-actions test README](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally).

## Uninstall

```bash
remove-module --no-preserve grantora1
```
