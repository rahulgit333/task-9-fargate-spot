data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "ecs" {
  name        = "task-9-ecs-sg"
  description = "Allow HTTP traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "main" {
  name = "task-9-cluster"
}

resource "aws_ecs_task_definition" "my_strapi_app" {
  family                   = "task-9-my-strapi-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name  = "my-strapi-app"
      image = "${aws_ecr_repository.my_strapi_app.repository_url}:latest"
      essential = true

      portMappings = [{
        containerPort = 1337
        hostPort      = 1337
      }]
    }
  ])
}

resource "aws_ecs_service" "my_strapi_service" {
  name            = "task-9-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.my_strapi_app.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }
}
