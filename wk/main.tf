provider "google" {
  credentials = file("account.json")
  project = var.project
}

module "wk" {
  source     = "./modules/wk"
  image_name = var.image_name
  region     = var.region
}
