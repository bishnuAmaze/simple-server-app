provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "simple_server_app_service_rg" {
  name     = "rg-simple-server-service-sea-0001"
  location = "southeastasia"
}

resource "azurerm_log_analytics_workspace" "simple_server_app_service_aw" {
  name                = "simple-server-app-service-workspace"
  location            = azurerm_resource_group.simple_server_app_service_rg.location
  resource_group_name = azurerm_resource_group.simple_server_app_service_rg.name
}

resource "azurerm_container_app_environment" "simple_server_app_cae" {
  name                       = "simple-server-app-cae"
  location                   = azurerm_resource_group.simple_server_app_service_rg.location
  resource_group_name        = azurerm_resource_group.simple_server_app_service_rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.simple_server_app_service_aw.name
}

resource "azurerm_container_app" "simple_server_app_ca_docker_hub" {
  name                         = "simple-server-app-ca-dh"
  container_app_environment_id = azurerm_container_app_environment.simple_server_app_cae.name
  resource_group_name          = azurerm_resource_group.simple_server_app_service_rg.name
  revision_mode                = "Single"

  registry {
    server               = "docker.io"
    username             = var.docker_hub_username
    password_secret_name = "docker-io-pass"
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 3000

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }

  }

  template {
    container {
      name   = "${var.resource_id_prefix}-simple-server-app-container-dh"
      image  = "${var.docker_hub_registry_name}/${var.simple_server_app_container_name}:${var.simple_server_app_container_tag_dh}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "CONTAINER_REGISTRY_NAME"
        value = "Docker Hub"
      }
    }
  }

  secret {
    name  = "docker-io-pass"
    value = var.docker_hub_password
  }
}