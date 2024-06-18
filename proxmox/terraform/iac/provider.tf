##asignar una variable de tipo cadena para almacenar la URL de la api de Proxmox
variable "pm_api_url" {
  type = string
}

## Le decimos a terraform que vamos a usar el provider de Telmate para proxmox
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

##Configuramos la url de proxmox  de la API del provider
provider "proxmox" {
  pm_api_url = var.pm_api_url
}

##Configuramos la API del provider de Cloudflare
provider "cloudflare" {
  # token pulled from $CLOUDFLARE_API_TOKEN
}


    