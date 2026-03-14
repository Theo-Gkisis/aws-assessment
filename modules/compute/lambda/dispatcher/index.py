import json
import os
import uuid
import boto3
from datetime import datetime, timezone

ecs = boto3.client("ecs")

CLUSTER_ARN = os.environ["ECS_CLUSTER_ARN"]
TASK_DEFINITION = os.environ["ECS_TASK_DEFINITION"]
SUBNET_IDS = os.environ["SUBNET_IDS"].split(",")
SECURITY_GROUP_ID = os.environ["SECURITY_GROUP_ID"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
EMAIL = os.environ["CANDIDATE_EMAIL"]
GITHUB_REPO = os.environ["GITHUB_REPO"]
REGION = os.environ["AWS_REGION"]


def handler(event, context):
    print(f"[dispatcher] Invoked in region={REGION} cluster={CLUSTER_ARN}")

    # JWT claims injected by API Gateway JWT Authorizer
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("jwt", {})
        .get("claims", {})
    )
    user_email = claims.get("email", "unknown")
    print(f"[dispatcher] Authenticated user_email={user_email}")

    request_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    print(f"[dispatcher] Launching ECS task request_id={request_id} task_definition={TASK_DEFINITION}")
    # ── Launch ECS Fargate task (task publishes to SNS) ───────────────────────
    response = ecs.run_task(
        cluster=CLUSTER_ARN,
        taskDefinition=TASK_DEFINITION,
        launchType="FARGATE",
        networkConfiguration={
            "awsvpcConfiguration": {
                "subnets": SUBNET_IDS,
                "securityGroups": [SECURITY_GROUP_ID],
                "assignPublicIp": "ENABLED",
            }
        },
        overrides={
            "containerOverrides": [
                {
                    "name": "sns-publisher",
                    "environment": [
                        {"name": "SNS_TOPIC_ARN", "value": SNS_TOPIC_ARN},
                        {"name": "CANDIDATE_EMAIL", "value": EMAIL},
                        {"name": "GITHUB_REPO", "value": GITHUB_REPO},
                        {"name": "REQUEST_ID", "value": request_id},
                        {"name": "TRIGGERED_BY", "value": user_email},
                        {"name": "REGION", "value": REGION},
                    ],
                }
            ]
        },
    )

    failures = response.get("failures", [])
    if failures:
        print(f"[dispatcher] ECS run_task FAILED failures={failures}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(
                {"error": "Failed to launch ECS task", "details": failures}
            ),
        }

    task_arn = response["tasks"][0]["taskArn"]
    print(f"[dispatcher] ECS task launched OK task_arn={task_arn}")

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "message": "ECS task dispatched successfully.",
                "request_id": request_id,
                "task_arn": task_arn,
                "region": REGION,
                "timestamp": timestamp,
            }
        ),
    }
