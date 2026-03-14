#!/usr/bin/env python3
"""
Test script — Unleash Live AWS Assessment

1. Read API URLs + Cognito client ID from terraform output
2. Authenticate with Cognito and get a JWT
3. POST /greet  in us-east-1 and eu-west-1 (concurrently)
4. POST /dispatch in us-east-1 and eu-west-1 (concurrently)
5. Print results and exit 0 if all passed

Usage:
    python scripts/test_deployment.py
"""

import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

import boto3

# ──────────────────────────────────────────────────────────────────────────────

COGNITO_REGION = "us-east-1"


def load_dotenv(path=".env"):
    if not os.path.exists(path):
        return
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            os.environ.setdefault(key.strip(), value.strip())


def terraform_outputs():
    result = subprocess.run(
        ["terraform", "output", "-json"],
        capture_output=True, text=True, check=True,
    )
    raw = json.loads(result.stdout)
    return {k: v["value"] for k, v in raw.items()}


def get_jwt(client_id, username, password):
    client = boto3.client("cognito-idp", region_name=COGNITO_REGION)
    resp = client.initiate_auth(
        AuthFlow="USER_PASSWORD_AUTH",
        AuthParameters={"USERNAME": username, "PASSWORD": password},
        ClientId=client_id,
    )
    return resp["AuthenticationResult"]["IdToken"]


def post(url, token):
    start = time.perf_counter()
    try:
        req = urllib.request.Request(
            url,
            data=b"{}",
            headers={"Authorization": token, "Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=20) as resp:
            ms   = round((time.perf_counter() - start) * 1000)
            body = json.loads(resp.read())
            return {"ok": True, "status": resp.status, "ms": ms, "body": body}
    except urllib.error.HTTPError as e:
        ms = round((time.perf_counter() - start) * 1000)
        return {"ok": False, "status": e.code, "ms": ms, "body": e.read().decode()}
    except Exception as e:
        ms = round((time.perf_counter() - start) * 1000)
        return {"ok": False, "status": None, "ms": ms, "body": str(e)}


def call_both(url_us, url_eu, token):
    with ThreadPoolExecutor(max_workers=2) as pool:
        f_us = pool.submit(post, url_us, token)
        f_eu = pool.submit(post, url_eu, token)
        return f_us.result(), f_eu.result()


def print_result(region, r, expected_region=None):
    """Print result and return True only if HTTP OK *and* all region assertions pass."""
    status = "PASS" if r["ok"] else "FAIL"
    body   = r["body"]

    print(f"  [{status}]  {region}  —  HTTP {r['status']}  ({r['ms']} ms)")

    if not (r["ok"] and isinstance(body, dict)):
        print(f"         error     : {body}")
        return False

    all_assertions_pass = True

    # ── Region field assertion ────────────────────────────────────────────────
    actual_region = body.get("region", "")
    region_ok     = (actual_region == expected_region) if expected_region else True
    region_icon   = "PASS" if region_ok else "FAIL"
    if not region_ok:
        all_assertions_pass = False

    if "message" in body:
        print(f"         message   : {body['message']}")
    if "request_id" in body:
        print(f"         req_id    : {body['request_id']}")
    print(f"         region    : [{region_icon}]  expected={expected_region}  got={actual_region}")

    # ── task_arn region assertion (dispatch only) ─────────────────────────────
    if "task_arn" in body:
        task_arn      = body["task_arn"]
        # ARN format: arn:aws:ecs:<region>:<account>:task/<cluster>/<id>
        arn_region    = task_arn.split(":")[3] if task_arn.count(":") >= 4 else ""
        arn_region_ok = (arn_region == expected_region) if expected_region else True
        arn_icon      = "PASS" if arn_region_ok else "FAIL"
        if not arn_region_ok:
            all_assertions_pass = False
        print(f"         task_arn  : {task_arn}")
        print(f"         arn_region: [{arn_icon}]  expected={expected_region}  got={arn_region}")

    return all_assertions_pass


# ──────────────────────────────────────────────────────────────────────────────

def main():
    load_dotenv()

    username = os.environ.get("TEST_USERNAME")
    if not username:
        print("ERROR: TEST_USERNAME not set (add to .env or export it)")
        return 1

    password = os.environ.get("TEST_USER_PASSWORD")
    if not password:
        print("ERROR: TEST_USER_PASSWORD not set (add to .env or export it)")
        return 1

    # 1. Terraform outputs
    print("Reading Terraform outputs ...")
    try:
        out = terraform_outputs()
    except subprocess.CalledProcessError as e:
        print(f"ERROR: terraform output failed:\n{e.stderr}")
        return 1

    base_us   = out["api_url_us"]
    base_eu   = out["api_url_eu"]
    client_id = out["cognito_client_id"]
    print(f"  us-east-1 : {base_us}")
    print(f"  eu-west-1 : {base_eu}")

    # 2. Authenticate
    print(f"\nAuthenticating as {username} ...")
    try:
        token = get_jwt(client_id, username, password)
    except Exception as e:
        print(f"ERROR: Cognito auth failed: {e}")
        return 1
    print(f"  JWT obtained  ({datetime.now(timezone.utc).isoformat()})")

    # 3. /greet
    print("\nStep 3 — POST /greet (both regions concurrently) ...")
    r_greet_us, r_greet_eu = call_both(f"{base_us}/greet", f"{base_eu}/greet", token)
    print()
    ok_greet_us = print_result("us-east-1", r_greet_us, "us-east-1")
    ok_greet_eu = print_result("eu-west-1", r_greet_eu, "eu-west-1")

    # 4. /dispatch
    print("\nStep 4 — POST /dispatch (both regions concurrently) ...")
    print("  (triggers a Fargate task that publishes to SNS)")
    r_disp_us, r_disp_eu = call_both(f"{base_us}/dispatch", f"{base_eu}/dispatch", token)
    print()
    ok_disp_us = print_result("us-east-1", r_disp_us, "us-east-1")
    ok_disp_eu = print_result("eu-west-1", r_disp_eu, "eu-west-1")

    # 5. Summary
    all_ok = all([ok_greet_us, ok_greet_eu, ok_disp_us, ok_disp_eu])
    print(f"\n{'═' * 50}")
    if all_ok:
        print("  RESULT: PASS — all endpoints OK in both regions.")
    else:
        print("  RESULT: FAIL — one or more endpoints failed.")
    print()

    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
