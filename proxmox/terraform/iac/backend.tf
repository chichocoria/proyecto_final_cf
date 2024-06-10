terraform {
  cloud {
    organization = "avatares-devops"

    workspaces {
      name = "avatares-devops-state"
    }
  }
}