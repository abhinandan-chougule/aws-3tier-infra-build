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

# Policy for S3 access
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
          "arn:aws:s3:::${var.artifact_bucket_name}/*"
        ]
      }
    ]
  })
}

# Attach SSM core policy as well (so you can connect via Session Manager)
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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
set -eux

# ===== Update system and install dependencies =====
apt update -y
apt upgrade -y
apt install -y openjdk-17-jdk-headless curl unzip

# ===== Install AWS CLI v2 =====
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.30.6.zip" -o "/tmp/awscliv2.zip"
cd /tmp
unzip awscliv2.zip
./aws/install
aws --version

# ===== Fetch the Spring Boot JAR from S3 =====
aws s3 cp "s3://${var.artifact_bucket_name}/${var.artifact_object_key}" /home/ubuntu/app.jar
chown ubuntu:ubuntu /home/ubuntu/app.jar

# ===== Create a systemd service =====
cat > /etc/systemd/system/petclinic.service <<EOF
[Unit]
Description=PetClinic Spring Boot App
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu
Environment=SPRING_PROFILES_ACTIVE=mysql
Environment=SPRING_DATASOURCE_URL=jdbc:mysql://${var.db_host}:${var.db_port}/${var.db_name}?useSSL=false&allowPublicKeyRetrieval=true
Environment=SPRING_DATASOURCE_USERNAME=${var.db_username}
Environment=SPRING_DATASOURCE_PASSWORD=${var.db_password}
ExecStart=/usr/bin/java -jar /home/ubuntu/app.jar
SuccessExitStatus=143
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable petclinic
systemctl start petclinic
EOT
)

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.project_name}-app" })
  }
}

# Auto Scaling Group
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
