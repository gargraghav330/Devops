#!/bin/bash
set -euo pipefail

# ------------------------
# Configurable variables
# ------------------------

# ------------------------
# Variables injected by Terraform
# ------------------------
export cluster_name="${cluster_name}"
export enable_ecs_instance_cw_logs="${enable_ecs_instance_cw_logs}"
export region="${region}"

# ------------------------
# Install dependencies
# ------------------------
dnf install -y docker ecs-init amazon-cloudwatch-agent amazon-ssm-agent jq curl unzip  --allowerasing

# ------------------------
# Enable and start Docker
# ------------------------
systemctl enable --now docker

until systemctl is-active --quiet docker; do
  sleep 2
done

# ------------------------
# ECS configuration
# ------------------------
mkdir -p /etc/ecs
echo "ECS_CLUSTER=${cluster_name}" > /etc/ecs/ecs.config
echo ECS_ENABLE_SPOT_INSTANCE_DRAINING=true >> /etc/ecs/ecs.config
# echo "ECS_ENABLE_TASK_ENI=true" >> /etc/ecs/ecs.config

# ------------------------
# Enable and start ECS agent non-blocking
# ------------------------
systemctl enable --now --no-block ecs

# ------------------------
# Start SSM Agent
# ------------------------
systemctl enable --now amazon-ssm-agent

# ------------------------
# CloudWatch Agent (optional)
# ------------------------
if [ "${enable_ecs_instance_cw_logs}" = "true" ]; then
    mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

    cat <<EOF >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": { "metrics_collection_interval": 60, "run_as_user": "root" },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/ecs/${cluster_name}/host/var/log/messages",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/docker",
            "log_group_name": "/ecs/${cluster_name}/host/var/log/docker",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/ecs/ecs-agent.log",
            "log_group_name": "/ecs/${cluster_name}/host/ecs-agent.log",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

    systemctl enable --now amazon-cloudwatch-agent
fi
