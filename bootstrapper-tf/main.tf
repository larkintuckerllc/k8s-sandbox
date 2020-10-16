provider "kubernetes" {
  config_context = var.config_context
}

module "bootstrapper" {
  source = "./modules/bootstrapper"
  image  = var.image
}

