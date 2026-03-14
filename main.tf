# ─── Authentication (us-east-1 only) ─────────────────────────────────────────
module "cognito" {
  source = "./modules/cognito"

  providers = {
    aws = aws.us_east_1
  }

  project_name       = local.project_name
  email              = var.test_username
  test_user_password = var.test_user_password
}

# ─── Networking us-east-1 ─────────────────────────────────────────────────────
module "networking_us" {
  source = "./modules/networking"

  providers = {
    aws = aws.us_east_1
  }

  project_name = local.project_name
  vpc_cidr     = var.vpc_cidr_us
  subnet_count = var.subnet_count
}

# ─── Networking eu-west-1 ─────────────────────────────────────────────────────
module "networking_eu" {
  source = "./modules/networking"

  providers = {
    aws = aws.eu_west_1
  }

  project_name = local.project_name
  vpc_cidr     = var.vpc_cidr_eu
  subnet_count = var.subnet_count
}

# ─── Compute us-east-1 ────────────────────────────────────────────────────────
module "compute_us" {
  source = "./modules/compute"

  providers = {
    aws = aws.us_east_1
  }

  project_name          = local.project_name
  region                = "us-east-1"
  email                 = local.email
  github_repo           = local.github_repo
  sns_topic_arn         = var.sns_topic_arn
  subnet_ids            = module.networking_us.public_subnet_ids
  ecs_security_group_id = module.networking_us.ecs_security_group_id
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_client_id     = module.cognito.client_id
  cognito_endpoint      = module.cognito.endpoint
  dynamodb_table_name   = var.dynamodb_table_name
  dynamodb_billing_mode = var.dynamodb_billing_mode
  lambda_runtime        = var.lambda_runtime
  lambda_timeout        = var.lambda_timeout
  lambda_memory_mb      = var.lambda_memory_mb
  ecs_task_cpu          = var.ecs_task_cpu
  ecs_task_memory       = var.ecs_task_memory
  ecs_container_image   = var.ecs_container_image
  api_stage_name        = var.api_stage_name
}

# ─── Compute eu-west-1 ────────────────────────────────────────────────────────
module "compute_eu" {
  source = "./modules/compute"

  providers = {
    aws = aws.eu_west_1
  }

  project_name          = local.project_name
  region                = "eu-west-1"
  email                 = local.email
  github_repo           = local.github_repo
  sns_topic_arn         = var.sns_topic_arn
  subnet_ids            = module.networking_eu.public_subnet_ids
  ecs_security_group_id = module.networking_eu.ecs_security_group_id
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_client_id     = module.cognito.client_id
  cognito_endpoint      = module.cognito.endpoint
  dynamodb_table_name   = var.dynamodb_table_name
  dynamodb_billing_mode = var.dynamodb_billing_mode
  lambda_runtime        = var.lambda_runtime
  lambda_timeout        = var.lambda_timeout
  lambda_memory_mb      = var.lambda_memory_mb
  ecs_task_cpu          = var.ecs_task_cpu
  ecs_task_memory       = var.ecs_task_memory
  ecs_container_image   = var.ecs_container_image
  api_stage_name        = var.api_stage_name
}
