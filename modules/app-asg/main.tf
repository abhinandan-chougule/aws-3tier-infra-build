# IAM role to read S3 artifacts
resource "aws_iam_role" "app_role" {
  name               = "${var.project_name}-app-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect   = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "s3_access" {
  name = "${var.project_name}-s3-access"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:ListBucket"],
        Resource = [
          "arn:aws:s3:::${var.artifact_bucket_name}",
          "arn:aws:s3:::${var.artifact_bucket_name}/${var.artifact_object_key}"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "${var.project_name}-app-profile"
  role = aws_iam_role.app_role.name
}

# Launch template
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = var.app_ami_id
  instance_type = var.instance_type
  key_name      = var.ec2_key_name

  vpc_security_group_ids = [var.app_security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }

  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -euo pipefail

    yum update -y
    yum install -y java-17-amazon-corretto-headless awscli

    mkdir -p /opt/app
    aws s3 cp s3://${var.artifact_bucket_name}/${var.artifact_object_key} /opt/app/app.jar

    # Systemd unit
    cat >/etc/systemd/system/app.service <<'UNIT'
    [Unit]
    Description=Spring Boot App
    After=network.target

    [Service]
    User=root
    ExecStart=/usr/bin/java -jar /opt/app/app.jar --server.port=8080
    Restart=always

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable app
    systemctl start app
  EOT
)

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.project_name}-app" })
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-asg"
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  vpc_zone_identifier       = var.private_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 60

  target_group_arns = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app"
    propagate_at_launch = true
  }
}