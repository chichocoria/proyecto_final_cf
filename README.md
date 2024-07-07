### Hi! I'm [Dario Coria](https://chicho.com.ar)👋

# Proyecto Final - Bootcamp Devops

### Requisitos Previos:

#### - Un hosts con las tools:
 * Kubectl
 * Helm
 * Terraform
 * Ansible
 * Jenkins
 * SonarQube

## Infraestructura como servicio

<p align="center">
<img src="https://github.com/chichocoria/proyecto_final_cf/assets/66035606/d641d6a4-d3e1-4d6e-93f2-e062ba75f653)"> 
</p>

 * Se utiliza Terraform comno IaC para correr sobre el hypervisor Proxmox y se usa el provider de Telmate.
 * Tambien se utiliza el provider de Cloudflare para agregar registros de tipo CNAME
 * Como configuracion management se usa Ansible para instalar Cluster RKE2

### Pasos para correr las VMS en donde vamos correr el cluster de RKE2

Primero debemos crear una plantilla desde una imagen de Ubuntu con cloud-init desde el Hipervisor Proxmox.
Todos estos pasos se hacen desde Proxmox.
```
##Descargarse la imagen
wget  https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

##Instalar libguestfs para inyectar qemu-guest-agent a la imagen asi nos brinda info de la IP desde la GUI de Proxmox
apt update -y && apt install libguestfs-tools -y

Inyectar qemu-guest-agent en la imagen que se descargo.
virt-customize -a jammy-server-cloudimg-amd64.img --install qemu-guest-agent

```

##### - Creacion del template:

```
qm create 9022 --name "ubuntu-2204-cloudinit-template" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9022 jammy-server-cloudimg-amd64.img hdd-img
qm set 9022 --scsihw virtio-scsi-pci --scsi0 hdd-img:9022/vm-9022-disk-0.raw
qm set 9022 --boot c --bootdisk scsi0
qm set 9022 --ide2 hdd-img:cloudinit
qm set 9022 --serial0 socket --vga serial0
qm set 9022 --agent enabled=1
qm template 9022
```

##### - Creacion de SSH Key para poder acceder:
```
#Generar clave SSH

ssh-keygen -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "nombre_usuario"

copiar contenido de la key publica en la GUI de Proxmox>>seleccionamos el template>>Cloud init>>SSH public key

```

##### - En el Hypervisor Proxmox conectarse por ssh

```
# 1. Crear Role
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt"

# 2. Crear User
# - note the command balks at special characters in the terminal
# - ended up resetting to strong password via GUI

pveum user add terraform-prov@pve --password <password>

# 3. Asociar el Rol con el Usuario
pveum aclmod / -user terraform-prov@pve -role TerraformProv
```

##### - Crear un api Token para usarlo en Terraform:

* En la GUI de Proxmox nos dirigimos a Datacenter>>API Tokens>>Add
* En User elejir el usuario terraform_user@pve
* Destildar "Privilege Separation"
* Guardar el Token en un lugar seguro para despues utilizarlo.

![image](https://github.com/chichocoria/proyecto_final_cf/assets/66035606/0e92969c-4dfb-4b56-a1b4-4de3e2fe862d)

---

## Terraform

> [!IMPORTANT]  
> Para mantener seguro nuestro archivo de estado en terraform se utlizo Terraform Cloud
 

##### - Pasos para instalar terraform sobre Ubuntu Server 22.04
```
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform
terraform -version
```

### Iniciar Terraform para aprovisionar la infraestructura en Proxmox
##### - En el siguiente ejemplo se van a crear:
 * 1 VM para control plane
 * 2 VMs para workers

##### - Clonarse el repositorio:
```
git clone https://github.com/chichocoria/proyecto_final_cf.git
```

##### - Dirigirse al directorio proxmox/terraform/iac/

```
cd proxmox/terraform/iac/
```

##### - Pasar por variables de entorno el usuario pass, api token id y api token secret para tener comunicacion con proxmox y con CloudFlare
```
export PM_USER="terraform-prov@pve"
export PM_PASS="password"
export PM_API_TOKEN_SECRET=<proxmox_token>
export PM_API_TOKEN_ID='terraform-prov@pve!infra'
export PM_API_TOKEN_SECRET="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export CLOUDFLARE_API_TOKEN=<cloudflare_token>
```

##### - Crear el archivo terraform.tfvars con las variables
```
##Definimos las variables para proxmox
pm_api_url              = "https://ip_proxmox:8006/api2/json"
cloudinit_template_name = "ubuntu-2204-cloudinit-template"
proxmox_node            = "<node_name>"
ssh_key                 = "<ssh-key>"

##Variables de Cloudflare
zone_id                 = "<zone_id>"
account_id              = "<account_id>" 
```

##### - Correr los siguientes comando en terraform
```
## Iniciar
terraform init
## Validar
terraform validate
## Plan para corroborar que se va a terraformar
terraform plan
## Apply para aplicar
terraform apply
```

Con estos pasos ya deberiamos tener la infraestructura para poder instalar Kubernetes.
 * 1 Server Master
 * 2 Server Workers
 * Los registros DNS para utlizar con el Ingress Controller

---

## Ansible
Se va a utlilzar Ansible como configuration management para la instalacion de RKE2 en el Server Control Plane y en los dos servers Workers.

### Explicacion de los Playbooks

##### - 01-puestaapunto.yaml
 * Ping a todos los hosts
 * Apt update y upgrade
 * Agrega los hostnames de los 3 server en el archivo hosts
 * Modifica el file cloud.cfg para q los hostnames queden persistentes
 * Instala Docker

##### - 02-install-rke2-master.yaml
 * Instala RKE2 en el master node
 * Copia el file config.yml del nodo master al host donde esta instalado Ansible
 * Crea la carpeta .kube
 * Copia el file config.yml, lo renombra a config y le cambia la IP 127.0.0.1 a la del servidor master

##### - 03-install-rke2-nodes.yaml
 * Instala RKE2 en los workers nodes
 * Extraer el token del nodo master
 * Crea el file config.yml y le agrega el token extraido y la url del master
 * Lo descarga en el hosts en el directorio /tmp
 * Lo copia a los nodos workers en el path /etc/rancher/rke2/

```
#Posicionarse en el siguiente directorio
cd ~/proyecto_final_cf/proxmox/ansible/

##Correr los playbooks
ansible-playbook -i hosts  playbooks/01-puestaapunto.yaml

ansible-playbook -i hosts  playbooks/02-install-rke2-master.yaml

ansible-playbook -i hosts  playbooks/03-install-rke2-nodes.yaml
```
Corriendo los 3 Playbooks, ya deberiamos tener un cluster de RKE2 totalmente funcional.
 * 1 Master
 * 2 Workers

![image](https://github.com/chichocoria/proyecto_final_cf/assets/66035606/beb51e2b-e982-4e4a-a321-c81c1e147f79)

### Instalar tools para el cluster RKE2

#### MetalLB
MetalLB es una implementación de balanceador de carga para cluster bare-metal kubernetes 
Se instala MetalLB en el cluster como loadbalancer, no hace falta instalar Nginx Controller por que viene por defecto en la instalacion de RKE2.

```
~/proyecto_final_cf$ k8s/metallb/instalar-metallb-helm.sh
```

#### Cert-Manager
es un controlador de certificados X.509 potente y extensible para cargas de trabajo de Kubernetes y OpenShift. Obtendrá certificados de una variedad de emisores, tanto emisores públicos populares como emisores privados, y garantizará que los certificados sean válidos y estén actualizados, e intentará renovar los certificados en un momento configurado antes de su vencimiento.

```
~/proyecto_final_cf$ k8s/cert-manager/instalar-cert-manager.sh
```

#### Argo-CD
Argo CD es una herramienta de entrega continua declarativa de GitOps para Kubernetes.

```
~/proyecto_final_cf$ k8s/argocd/instalar-argocd-helm.sh
```

> [!NOTE]
> Ya tenemos nuestro Cluster RKE2 con MetaLB, Nginx Controller, Cert-Manager y Argo CD. 

---

## Integracion Continua
Se utiliza jenkins como servidor de Integracion Continua.




---

## Probar aplicacion en un entorno de prueba con Docker-Compose
Instalar docker y docker compose
```
sudo apt update
sudo apt install docker.io docker-compose -y
```

Clonarse el repositorio:
```
git clone https://github.com/chichocoria/proyecto_final_cf.git
```

Dirigirse al directorio cd avatares-devops/

```
cd avatares-devops/
```

Correr docker-compose

```
docker-compose up -d
```

Acceder desde:
http://IP:5173/




## Instalar K3s para realizar los deploy de la aplicacion.
Desde mi blog hay una entrada de como instalar K3s.
[How to setup a Kubernetes Cluster with K3S and MetalLB on Proxmox](https://blog.chicho.com.ar/how-to-deploy-a-kubernetes-cluster-with-k3s/)


### Deployment del Back

Para hacer el deployment del back, vamos a ir al directorio k8s dentro del repo
```
cd k8s/
```

Crear un namespace llamado avatares
```
kubectl create namespace avatares
```

Aplicar el file 01-deployment-avatares-api.yaml, esto va a crear el deployment y tambien el service de tipo ClusterIP
```
kubectl apply -f 01-deployment-avatares-api.yaml -n avatares
```

Hacer un port-forward para verificar que el back esta funcionando
```
kubectl port-forward service/api 9080:5000 -n avatares
```

### Deployment del Front

Dentro del mismo directorio k8s


Aplicar el file 02-deployment-avatares-web.yaml, esto va a crear el deployment y tambien el service de tipo ClusterIP
```
kubectl apply -f 02-deployment-avatares-web.yaml -n avatares
```

Hacer un port-forward para verificar que el front esta funcionando correctamente y se pueda comunicar con el back
```
kubectl port-forward service/web 9081:5000 -n avatares
```

### Ingress para que pueda acceder desde afuera
Consideraciones a tener en cuenta.

* Debemos tener un LoadBalancer, en mi caso en K3s instale MetalLB
* Como controlador de ingreso instale nginx-ingress-controller
* Cert Managar instalado para asegurar el ingreso desde afuera con letsencrypt
* Un dominio: yo use el mio: chicho.com.ar
* Un DNS: utilizo la capa gratuita de Cloudflare, para hacer pruebas vamos a usar el subdomino avatares.chicho.com.ar

Hacer un kubectl apply del file 03-ingress-app-web.yaml
```
kubectl apply -f 03-ingress-app-web.yaml -n avatares
```

Si corremos un kubectl get ingress podemos verificar q se creo el ingres y el cert TLS
![image](https://github.com/chichocoria/proyecto_final_cf/assets/66035606/db108e77-cce9-4b6c-ad66-90840354204e)


Ahora podemos acceder a la URL para ver la aplicacion corriendo

[Avatares app](https://avatares.chicho.com.ar/)


## Monitoreo y Observabilidad del Cluster
Se instalo kube-prometheus-stack para metricas y loki-stack para logs de la aplicacion.
Si bien la aplicacion no logea demasiado, se puede apreciar cuando corre tanto el back como el front.


### Logs de la api
![image](https://github.com/chichocoria/proyecto_final_cf/assets/66035606/2152cf92-00d2-4294-bb27-c21077c1600b)

## Logs del front
![image](https://github.com/chichocoria/proyecto_final_cf/assets/66035606/23792138-5714-4118-915d-498cea593692)

## Monitoreo de la salud del Cluster
![image](https://github.com/chichocoria/proyecto_final_cf/assets/66035606/13039113-a387-453f-a54e-b3d8089f8938)



