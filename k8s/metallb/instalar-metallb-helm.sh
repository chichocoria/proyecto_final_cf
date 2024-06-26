#!/bin/bash

# Verifica si Helm está instalado
if ! command -v helm &> /dev/null
then
    echo "Helm no está instalado. Por favor, instala Helm primero."
    exit 1
fi

#1 - Agregar MetalLB al respositorio de Helm
helm repo add metallb https://metallb.github.io/metallb
#2 - Hacer un update del repo
helm repo update
#3 - Crear el namespace
kubectl create namespace metallb
#4 - Install metalLB en el namespace metallb
helm install metallb metallb/metallb --namespace metallb
#5 - Verificar la instalación
kubectl get pods -n metallb
#6 Aplicar la configuración de MetalLB
sleep 30
kubectl apply -f ~/proyecto_final_cf/k8s/metallb/metallb-config.yaml
# Verificar la configuración
kubectl get configmap -n metallb

echo "MetalLB ha sido instalado y configurado correctamente."

#Habilitar el controlador de ingreso Nginx como load balancer para que nos de IP MetalLB
helm repo add rke2-charts https://rke2-charts.rancher.io/
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install rke2-ingress-nginx ingress-nginx/ingress-nginx --set controller.publishService.enabled=true -n kube-system
sleep 10
#Verificar que nginx controller esta como LB
kubectl get svc rke2-ingress-nginx-controller -n kube-system
echo "Nginx controller OK como tipo LoadBalancer"