provider "aws" {
  region = "il-central-1"
}

data "aws_ecs_cluster" "cluster" {
  cluster_name = "imtech"
}

data "aws_iam_role" "role" {
  name = "AWSServiceRoleForECS"
}

data "aws_security_group" "sg" {
  name = "launch-wizard-4"
}

data "aws_subnets" "subnets" {
  filter {
    name   = "tag:Name"
    values = ["imtech-private-1", "imtech-private-2"]
  }
}

variable "es_url" {
  default = "http://172.30.20.131:9200"
}

resource "aws_cloudwatch_log_group" "filebeat_nginx" {
  name              = "/ecs/imtech-dor-filebeat-nginx"
  retention_in_days = 14
}


resource "aws_ecs_task_definition" "filebeat_nginx" {
  family                   = "filebeat-nginx"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = data.aws_iam_role.role.arn

  volume {
    name = "nginx-logs"
  }

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "nginx-logs"
          containerPath = "/var/log/nginx"
          readOnly      = false
        }
      ]
    },

    {
      name      = "filebeat"
      image     = "314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/filebeat:latest"
      essential = true

      command = [
        "filebeat",
        "-e",
        "-c",
        "/usr/share/filebeat/filebeat.yml"
      ]

      environment = [
        {
          name  = "ELASTICSEARCH_HOST"
          value = var.es_url
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "nginx-logs"
          containerPath = "/logs"
          readOnly      = true
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.filebeat_nginx.name
          awslogs-region        = "il-central-1"
          awslogs-stream-prefix = "filebeat"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "filebeat_nginx" {
  name            = "filebeat-nginx-svc"
  cluster         = data.aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.filebeat_nginx.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.subnets.ids
    security_groups  = [data.aws_security_group.sg.id]
    assign_public_ip = true
  }
}
