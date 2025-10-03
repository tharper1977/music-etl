# python
import os
import subprocess
import sys
import pytest
import pathlib

# Integration test: attempt to run the real ETL entrypoint.
# This is expected to fail in the CI/dev environment (no DBs / missing env vars).
#
# We run the script as a subprocess so the test run cannot pollute the test process
# state (env, modules). The expectation is that the process exits with non-zero code.
#
# If you later wire up real test databases and credentials, change this test to
# assert the successful end-to-end behaviour (or make it conditional via markers).

ETL_SCRIPT = str(pathlib.Path(__file__).resolve().parents[1] / "run_etl.py")

pytestmark = pytest.mark.integration

@pytest.fixture(autouse=True)
def integration_enabled_or_skip():
    # Skip the test unless INTEGRATION env var is explicitly true (string '1' or 'true').
    val = os.environ.get("", "").lower()
    if val not in ("1", "true", "yes"):
        pytest.skip("Integration tests disabled (set INTEGRATION=1 to enable)")

def test_integration_run_etl_real_environment():
    """
    Run the real ETL entrypoint and assert it completes successfully in a configured environment.
    Pre-requisites:
      - Configure required environment variables (e.g. PG_DSN, MSSQL_CONN) or other secrets
      - Ensure destination/source DBs are reachable and set up for test (isolated test schemas)
    """
    # run with same interpreter as test environment
    result = subprocess.run([sys.executable, ETL_SCRIPT], capture_output=True, text=True)
    assert result.returncode == 0, f"ETL failed: stdout={result.stdout}\nstderr={result.stderr}"

    # Optionally: add additional verification here (DB queries) to verify inserted/updated rows.
