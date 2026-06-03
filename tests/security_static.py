#!/usr/bin/env python3

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RESERVED_PORTS = {2379, 5432, 8080, 9180}
REDACTION_SAMPLES = (
    'Authorization: Bearer grantora-admin-secret',
    'ADMIN_BOOTSTRAP_TOKEN=grantora-admin-secret',
    '{"secret_value":"raw-secret","agent_token":"plain-token"}',
)
SECRET_VALUES = ("grantora-admin-secret", "raw-secret", "plain-token")


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def load_namespace(script: str) -> dict[str, object]:
    path = ROOT / script
    namespace = {"__file__": str(path), "__name__": "security_static_target"}
    exec(compile(path.read_text(encoding="utf-8"), script, "exec"), namespace)
    return namespace


def assert_redaction(script: str) -> None:
    namespace = load_namespace(script)
    redact = namespace.get("redact")
    assert callable(redact), f"{script} must expose redact()"
    for sample in REDACTION_SAMPLES:
        redacted = redact(sample)
        assert "<redacted>" in redacted, f"{script} did not mark redacted data"
        for secret_value in SECRET_VALUES:
            assert secret_value not in redacted, f"{script} leaked {secret_value}"


def test_redaction_helpers() -> None:
    for script in (
        "imageroot/bin/grantora-admin",
        "imageroot/actions/configure-module/90sync_apisix",
        "imageroot/bin/grantora-smoke",
        "imageroot/bin/grantora-status",
        "imageroot/bin/grantora-operations",
        "imageroot/bin/grantora-users",
        "imageroot/actions/restore-module/20restore",
        "imageroot/bin/grantora-lifecycle",
    ):
        assert_redaction(script)


def test_pod_port_boundary() -> None:
    pod_unit = read("imageroot/systemd/user/grantora-pod.service")
    assert "--publish=127.0.0.1:${TCP_PORT}:9080" in pod_unit
    for unit in (ROOT / "imageroot/systemd/user").glob("grantora-*.service"):
        if unit.name == "grantora-pod.service":
            continue
        assert "--publish" not in unit.read_text(encoding="utf-8"), unit.name


def test_reserved_runtime_ports() -> None:
    schema = json.loads(read("imageroot/actions/configure-module/validate-input.json"))
    reserved = set(schema["properties"]["tcp_port"]["not"]["enum"])
    assert reserved == RESERVED_PORTS
    assert "RESERVED_TCP_PORTS = {8080, 9180, 5432, 2379}" in read("imageroot/bin/grantora-env")


def test_secret_modes_and_oidc_disabled() -> None:
    env_helper = read("imageroot/bin/grantora-env")
    assert "path.chmod(stat.S_IRUSR | stat.S_IWUSR)" in env_helper
    assert '"GRANTORA_JSON_LOGS": "true"' in env_helper
    assert '"FEATURE_OIDC": "false"' in env_helper
    assert '"OIDC_ADMIN_SUBJECTS": ""' in env_helper


def test_observability_helpers_keep_private_surfaces_private() -> None:
    operations = read("imageroot/bin/grantora-operations")
    pod_exec = read("imageroot/bin/grantora-pod-exec")
    retention_action = read("imageroot/actions/run-retention/20retention")
    status_helper = read("imageroot/bin/grantora-status")

    assert "http://127.0.0.1:8080/metrics" in operations
    assert "journalctl" in operations
    assert "ALLOWED_LOG_UNITS" in operations
    assert "operations_helper" in pod_exec
    assert 'payload.get("dry_run", True)' in retention_action
    assert '"helper_command": "grantora-pod-exec metrics"' in status_helper


def test_no_shell_tracing_in_actions_or_helpers() -> None:
    for base in (ROOT / "imageroot/actions", ROOT / "imageroot/bin"):
        for path in base.rglob("*"):
            if path.is_file():
                try:
                    text = path.read_text(encoding="utf-8")
                except UnicodeDecodeError:
                    continue
                assert "set -x" not in text, str(path.relative_to(ROOT))
                assert "xtrace" not in text.lower(), str(path.relative_to(ROOT))


def test_application_base_url_contract() -> None:
    schema = json.loads(read("imageroot/actions/create-application/validate-input.json"))
    assert schema["properties"]["base_url"]["pattern"] == r"^https?://[^\s/?#]+[^\s]*$"
    assert "safe_base_url" in read("imageroot/bin/grantora-bootstrap")
    assert "validateApplicationBaseUrl" in read("ui/src/views/Resources.vue")


if __name__ == "__main__":
    tests = [value for name, value in globals().items() if name.startswith("test_")]
    for test in tests:
        test()