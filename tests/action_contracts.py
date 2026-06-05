#!/usr/bin/env python3

import hashlib
import hmac
import json
import os
import stat
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def load_json(path: str) -> dict[str, object]:
    value = json.loads(read(path))
    assert isinstance(value, dict), f"{path} must contain a JSON object"
    return value


def load_namespace(script: str) -> dict[str, object]:
    path = ROOT / script
    namespace = {"__file__": str(path), "__name__": "contract_static_target"}
    exec(compile(path.read_text(encoding="utf-8"), script, "exec"), namespace)
    return namespace


def parse_envfile(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if not raw_line or raw_line.startswith("#") or "=" not in raw_line:
            continue
        key, value = raw_line.split("=", 1)
        values[key] = value
    return values


def run_helper(helper: str, command: str, state_directory: Path, stdin: object | None = None) -> str:
    env = os.environ | {"STATE_DIRECTORY": str(state_directory)}
    payload = None if stdin is None else json.dumps(stdin)
    result = subprocess.run(
        [str(ROOT / helper), command],
        input=payload,
        text=True,
        capture_output=True,
        env=env,
        check=False,
    )
    assert result.returncode == 0, result.stderr or result.stdout
    return result.stdout


def test_action_schemas_are_valid_and_strict() -> None:
    schema_paths = sorted((ROOT / "imageroot/actions").rglob("validate-*.json"))
    assert schema_paths, "action schemas must exist"
    schema_ids: set[str] = set()
    for path in schema_paths:
        schema = json.loads(path.read_text(encoding="utf-8"))
        assert schema.get("$schema") == "http://json-schema.org/draft-07/schema#", path
        schema_id = schema.get("$id")
        assert isinstance(schema_id, str) and schema_id.startswith("http://schema.nethserver.org/grantora/"), path
        assert schema_id not in schema_ids, f"duplicate schema id: {schema_id}"
        schema_ids.add(schema_id)
        if path.name == "validate-input.json":
            assert schema.get("additionalProperties") is False, path


def test_configure_schema_matches_env_renderer_inputs() -> None:
    schema = load_json("imageroot/actions/configure-module/validate-input.json")
    env_namespace = load_namespace("imageroot/bin/grantora-env")
    input_to_env = env_namespace["INPUT_TO_ENV"]
    assert isinstance(input_to_env, dict)
    properties = schema["properties"]
    for input_name in input_to_env:
        assert input_name in properties, f"{input_name} is rendered but missing from schema"
    assert "user_domain" in properties
    assert "ldap_user_domain" in properties
    assert set(properties["tcp_port"]["not"]["enum"]) == {2379, 5432, 8080, 9180}


def test_env_rendering_is_idempotent_and_preserves_secrets() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        state_root = Path(tmp)
        config = {
            "host": "grantora.example.test",
            "lets_encrypt": False,
            "user_domain": "accounts.example.test",
            "metrics_enabled": True,
            "log_level": "INFO",
            "audit_retention_days": 90,
            "usage_retention_days": 45,
            "runtime_rate_limit_count": 50,
            "runtime_rate_limit_time_window": 30,
            "upstream_timeout_seconds": 20,
            "upstream_connect_timeout_seconds": 4,
            "upstream_tls_verify": True,
            "tcp_port": 19080,
        }
        run_helper("imageroot/bin/grantora-env", "configure", state_root, config)
        state_dir = state_root / "state"
        first_secrets = parse_envfile(state_dir / "secrets.env")
        run_helper("imageroot/bin/grantora-env", "render", state_root)
        second_secrets = parse_envfile(state_dir / "secrets.env")

        assert first_secrets == second_secrets
        digest = hmac.new(
            first_secrets["GRANTORA_AGENT_TOKEN_PEPPER"].encode(),
            first_secrets["ADMIN_BOOTSTRAP_TOKEN"].encode(),
            hashlib.sha256,
        ).hexdigest()
        assert first_secrets["GRANTORA_ADMIN_BOOTSTRAP_TOKEN_HASH"] == f"hmac-sha256:{digest}"
        assert stat.S_IMODE((state_dir / "secrets.env").stat().st_mode) == 0o600
        assert stat.S_IMODE((state_dir / "postgres.env").stat().st_mode) == 0o600
        assert stat.S_IMODE((state_dir / "apisix-config.yaml").stat().st_mode) == 0o644

        environment = parse_envfile(state_dir / "environment")
        grantora_env = parse_envfile(state_dir / "grantora.env")
        runtime_env = parse_envfile(state_dir / "runtime.env")
        assert environment["GRANTORA_PUBLIC_BASE_URL"] == "https://grantora.example.test"
        assert environment["LDAP_USER_DOMAIN"] == "accounts.example.test"
        assert grantora_env["GRANTORA_JSON_LOGS"] == "true"
        assert grantora_env["METRICS_ENABLED"] == "true"
        assert grantora_env["AUDIT_RETENTION_DAYS"] == "90"
        assert grantora_env["USAGE_RETENTION_DAYS"] == "45"
        assert "DATABASE_URL" not in grantora_env
        assert first_secrets["DATABASE_URL"].startswith("postgresql+psycopg://grantora:")
        assert runtime_env["APISIX_ADMIN_URL"] == "http://127.0.0.1:9180"
        assert runtime_env["APISIX_RUNTIME_UPSTREAM_NODE"] == "127.0.0.1:8080"
        assert "${APISIX_ADMIN_KEY}" in (state_dir / "apisix-config.yaml").read_text(encoding="utf-8")

        (state_dir / "apisix-config.yaml").chmod(0o600)
        run_helper("imageroot/bin/grantora-env", "render", state_root)
        assert stat.S_IMODE((state_dir / "apisix-config.yaml").stat().st_mode) == 0o644


def test_configure_schema_accepts_get_configuration_round_trip_fields() -> None:
    schema = load_json("imageroot/actions/configure-module/validate-input.json")
    properties = schema["properties"]
    assert isinstance(properties, dict)
    for field in (
        "configured",
        "files",
        "ldap_user_domain",
        "public_base_url",
        "available_user_domains",
        "user_domain_discovery_error",
        "user_sync",
    ):
        assert field in properties, f"missing round-trip field: {field}"


def test_env_rendering_generates_hidden_tcp_port_when_not_provided() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        state_root = Path(tmp)
        config = {
            "host": "grantora.example.test",
            "lets_encrypt": True,
            "metrics_enabled": True,
            "log_level": "INFO",
        }

        run_helper("imageroot/bin/grantora-env", "configure", state_root, config)
        first_environment = parse_envfile(state_root / "state" / "environment")
        first_port = int(first_environment["TCP_PORT"])

        assert first_port not in {2379, 5432, 8080, 9180}
        assert first_port != 9080

        run_helper("imageroot/bin/grantora-env", "configure", state_root, config)
        second_environment = parse_envfile(state_root / "state" / "environment")

        assert int(second_environment["TCP_PORT"]) == first_port


def test_domain_discovery_sanitizes_provider_metadata() -> None:
    namespace = load_namespace("imageroot/bin/grantora-users")
    sanitized_domain = namespace["sanitized_domain"]
    domain = {
        "schema": "rfc2307",
        "location": "internal",
        "host": "ldap.example.test",
        "port": 389,
        "bind_password": "must-not-leak",
        "providers": [{"module_id": "ns8-openldap1", "password": "must-not-leak"}],
    }
    result = sanitized_domain("accounts.example.test", domain, "accounts.example.test")
    assert result == {
        "name": "accounts.example.test",
        "schema": "rfc2307",
        "location": "internal",
        "provider_module": "ns8-openldap1",
        "reachable": True,
        "selected": True,
    }


def test_safe_admin_error_does_not_leak_secret_payloads() -> None:
    namespace = load_namespace("imageroot/bin/grantora-bootstrap")
    safe_admin_error = namespace["safe_admin_error"]
    completed = subprocess.CompletedProcess(
        ["grantora-admin"],
        1,
        "",
        json.dumps(
            {
                "error": {
                    "code": "invalid_secret",
                    "message": "secret rejected",
                    "secret_value": "raw-secret",
                }
            }
        ),
    )
    message = safe_admin_error("POST", "/v1/admin/secrets", completed)
    assert message == "POST /v1/admin/secrets failed with exit code 1 (invalid_secret: secret rejected)"
    assert "raw-secret" not in message


if __name__ == "__main__":
    tests = [value for name, value in globals().items() if name.startswith("test_")]
    for test in tests:
        test()
