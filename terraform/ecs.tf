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
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi.arn
    container_name   = "my-strapi-app"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.http]
}
