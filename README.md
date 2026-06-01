# ns8-grantora

`ns8-grantora` packages the Grantora Agent Capability Gateway for NethServer 8 without forking upstream Grantora application logic.

Milestone 1 adds the pod-based runtime packaging skeleton described in [PLAN.md](PLAN.md). It starts Grantora as one rootless Podman pod with helper containers managed by separate user systemd units.

## Current scope

- Repository identity is `ns8-grantora` across docs, tests, UI metadata, and image build output.
- The module image reserves one TCP port for the APISIX runtime route.
- NS8 authorizations are prepared for Traefik route management and account-domain consumption.
- The runtime skeleton creates one Podman pod named `grantora` and publishes only `127.0.0.1:${TCP_PORT}:9080`.
- PostgreSQL, APISIX etcd, Grantora API, and APISIX each have their own inspectable user service.
- Generated env files and module secrets are rendered under `state/`; secret-bearing files are written with mode `0600`.
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

At this milestone `configure-module` renders default state/env files and restarts the runtime skeleton. It does not yet create the public Traefik route; that lands in Milestone 2.

```bash
api-cli run module/grantora1/configure-module --data '{}'
```

The action starts `grantora.service`, which pulls and runs the configured upstream Grantora, PostgreSQL, APISIX etcd, and APISIX images. By default the public-facing route is still absent, and the only host port mapping is the loopback APISIX runtime port owned by `grantora-pod.service`.

Useful service checks on the module instance:

```bash
systemctl --user status grantora.service
systemctl --user status grantora-postgres.service
systemctl --user status grantora-apisix-etcd.service
systemctl --user status grantora-api.service
systemctl --user status grantora-apisix.service
podman pod port grantora
```

## Roadmap

- Public runtime routing, richer status reporting, user-domain binding, and backup/restore are tracked in [PLAN.md](PLAN.md) as later milestones.

## Tests

This repository uses the NS8 testing infrastructure. For local execution guidance, refer to the [ns8-github-actions test README](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally).

## Uninstall

```bash
remove-module --no-preserve grantora1
```
