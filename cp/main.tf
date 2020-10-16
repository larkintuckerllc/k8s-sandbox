provider "google" {
  credentials = file("account.json")
  project = var.project
}

module "cp" {
  source     = "./modules/cp"
  image_name = var.image_name
  region     = var.region
  zone       = var.zone
}
