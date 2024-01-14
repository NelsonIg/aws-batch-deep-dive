# ECR Repository where the image is stored
resource "aws_ecr_repository" "this" {
  name = "${var.prefix}-ecr-repository"
  force_delete = true
}

# Compute ENV
resource "aws_batch_compute_environment" "this" {
  compute_environment_name_prefix = var.prefix

  compute_resources {
    max_vcpus = 4

    security_group_ids = var.security_group_ids
    subnets = var.subnet_ids

    type = "FARGATE"
  }

  service_role = aws_iam_role.service_role.arn
  type         = "MANAGED"
  depends_on   = [aws_iam_role_policy_attachment.service_role]
}

data "aws_iam_policy_document" "batch_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "service_role" {
  name               = "${var.prefix}-batch-service-role"
  assume_role_policy = data.aws_iam_policy_document.batch_assume_role.json
}

resource "aws_iam_role_policy_attachment" "service_role" {
  role       = aws_iam_role.service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# JOB Definition
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.prefix}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role" "job_role" {
  name               = "${var.prefix}-job-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "job_role_policy" {
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
      "arn:aws:s3:::${var.bucket_name}",
    ]
  }
}

resource "aws_iam_policy" "job_role_policy" {
  name   = "${var.prefix}-job-role-policy"
  policy = data.aws_iam_policy_document.job_role_policy.json
  
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "job_role_policy" {
  role       = aws_iam_role.job_role.name
  policy_arn = aws_iam_policy.job_role_policy.arn
}

resource "aws_batch_job_definition" "this" {
  name = "${var.prefix}-job-definition"
  type = "container"

  platform_capabilities = [
    "FARGATE",
  ]

  
  container_properties = jsonencode({
    command    = ["python", "script.py"]
    image      = "${aws_ecr_repository.this.repository_url}:latest"
    jobRoleArn = aws_iam_role.job_role.arn

    fargatePlatformConfiguration = {
      platformVersion = "1.4.0"
    }

    networkConfiguration = {
      assignPublicIp = "ENABLED"
    }

    runtimePlatform = {
      cpuArchitecture = "X86_64"
      operatingSystemFamily = "LINUX"
    }
    resourceRequirements = [
      {
        type  = "VCPU"
        value = "0.25"
      },
      {
        type  = "MEMORY"
        value = "512"
      }
    ]

    executionRoleArn = aws_iam_role.ecs_task_execution_role.arn
  })
}

# JOB Queue
resource "aws_batch_job_queue" "this" {
  name     = "${var.prefix}-job-queue"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.this.arn,
  ]
}