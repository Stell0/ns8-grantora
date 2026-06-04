#!/usr/bin/env python3

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PRIVATE_PORTS = {"2379", "5432", "8080", "9180"}
RUNTIME_UNITS = {
    "grantora-postgres.service": "grantora-postgres",
    "grantora-apisix-etcd.service": "grantora-apisix-etcd",
    "grantora-api.service": "grantora-api",
    "grantora-apisix.service": "grantora-apisix",
}


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_systemd_pod_topology_contract() -> None:
    pod_unit = read("imageroot/systemd/user/grantora-pod.service")
    assert "pod create --replace --name=grantora" in pod_unit
    assert "--publish=127.0.0.1:${TCP_PORT}:9080" in pod_unit
    for port in PRIVATE_PORTS:
        assert f":{port}" not in pod_unit.replace(":9080", "")

    aggregate = read("imageroot/systemd/user/grantora.service")
    for unit_name in RUNTIME_UNITS:
        assert f"Wants={unit_name}" in aggregate
        assert f"After={unit_name}" in aggregate
    for state_file in (
        "environment",
        "secrets.env",
        "runtime.env",
        "grantora.env",
        "postgres.env",
        "apisix.env",
        "apisix-config.yaml",
    ):
        assert f"ConditionPathExists=%S/state/{state_file}" in aggregate

    for unit_name, container_name in RUNTIME_UNITS.items():
        unit = read(f"imageroot/systemd/user/{unit_name}")
        assert "--pod=grantora" in unit
        assert f"--name={container_name}" in unit
        assert "--publish" not in unit
        assert "Environment=PODMAN_SYSTEMD_UNIT=%n" in unit
        assert "ExecStop=" in unit
        assert "ExecStopPost=" in unit

    api_unit = read("imageroot/systemd/user/grantora-api.service")
    assert "Requires=grantora-pod.service grantora-postgres.service grantora-apisix-etcd.service" in api_unit
    assert "--env-file=%S/state/grantora.env --env-file=%S/state/secrets.env" in api_unit

    etcd_unit = read("imageroot/systemd/user/grantora-apisix-etcd.service")
    assert "%S/state/apisix-etcd-data:/bitnami/etcd:Z,U" in etcd_unit

    apisix_unit = read("imageroot/systemd/user/grantora-apisix.service")
    assert "Requires=grantora-pod.service grantora-api.service grantora-apisix-etcd.service" in apisix_unit
    assert "%S/state/apisix-config.yaml:/usr/local/apisix/conf/config.yaml:ro,Z" in apisix_unit


def test_lifecycle_restore_and_security_smoke_contracts() -> None:
    smoke = read("imageroot/bin/grantora-smoke")
    assert "runtime_private_paths" in smoke
    assert "pod_port_exposure" in smoke
    assert "secret_file_modes" in smoke
    assert "runtime_discovery" in smoke

    restore = read("imageroot/actions/restore-module/20restore")
    assert "restore_database()" in restore
    assert "sync_apisix()" in restore
    assert "run_smoke()" in restore

    upgrade = read("imageroot/bin/grantora-lifecycle")
    assert "backup_for_upgrade" in upgrade
    assert "container_image_snapshot" in upgrade
    assert "rollback_on_failure" in upgrade


def test_build_image_declares_runtime_scan_targets() -> None:
    build_script = read("build-images.sh")
    assert "org.nethserver.images=" in build_script
    for image in (
        "ghcr.io/grantora/grantora-api:0.1.0",
        "docker.io/library/postgres:16-alpine",
        "docker.io/bitnamilegacy/etcd:3.5",
        "docker.io/apache/apisix:3.10.0-debian",
    ):
        assert image in build_script


def test_ci_runs_static_unit_security_build_and_robot_gates() -> None:
    lint_workflow = read(".github/workflows/lint-module.yml")
    assert "Run action contract checks" in lint_workflow
    assert "Run systemd and lifecycle contract checks" in lint_workflow
    assert "Run static security checks" in lint_workflow
    assert "tests/action_contracts.py" in lint_workflow
    assert "tests/systemd_contracts.py" in lint_workflow
    assert "tests/security_static.py" in lint_workflow

    module_workflow = read(".github/workflows/test-module.yml")
    assert "NethServer/ns8-github-actions/.github/workflows/test-module.yml@v1" in module_workflow

    publish_workflow = read(".github/workflows/publish-images.yml")
    assert "publish-branch.yml@v1" in publish_workflow
    assert "scan-with-trivy.yml@v1" in publish_workflow


if __name__ == "__main__":
    tests = [value for name, value in globals().items() if name.startswith("test_")]
    for test in tests:
        test()