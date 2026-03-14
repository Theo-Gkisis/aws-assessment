import json
import os
import uuid
import time
import boto3
from datetime import datetime, timezone

dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

# arn:aws:sns:<region>:<account>:<name>  →  extract region so cross-region publish works
_sns_region = SNS_TOPIC_ARN.split(":")[3]
sns = boto3.client("sns", region_name=_sns_region)
EMAIL = os.environ["CANDIDATE_EMAIL"]
GITHUB_REPO = os.environ["GITHUB_REPO"]
REGION = os.environ["AWS_REGION"]

TTL_DAYS = 7

def handler(event, context):
    print(f"[greeter] Invoked in region={REGION} table={TABLE_NAME}")

    # JWT claims injected by API Gateway JWT Authorizer
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("jwt", {})
        .get("claims", {})
    )
    user_email = claims.get("email", "unknown")
    print(f"[greeter] Authenticated user_email={user_email}")

    request_id = str(uuid.uuid4())
    now = int(time.time())
    timestamp = datetime.now(timezone.utc).isoformat()

    greeting = f"Hello, {user_email}! Greetings from {REGION}."

    # ── Write greeting log to DynamoDB ───────────────────────────────────────
    table = dynamodb.Table(TABLE_NAME)
    table.put_item(
        Item={
            "request_id": request_id,
            "timestamp": timestamp,
            "user_email": user_email,
            "region": REGION,
            "greeting": greeting,
            "expires_at": now + TTL_DAYS * 24 * 3600,
        }
    )
    print(f"[greeter] DynamoDB write OK request_id={request_id}")

    # ── Publish verification payload to SNS ──────────────────────────────────
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps(
            {
                "email": EMAIL,
                "source": "Lambda",
                "region": REGION,
                "repo": GITHUB_REPO,
            }
        ),
    )
    print(f"[greeter] SNS publish OK topic={SNS_TOPIC_ARN}")

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "message": greeting,
                "request_id": request_id,
                "region": REGION,
            }
        ),
    }
