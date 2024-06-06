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
kubectl get pods -n metallb-system
#6 Aplicar la configuración de MetalLB
kubectl apply -f metallb-config.yaml
# Verificar la configuración
kubectl get configmap -n metallb-system

echo "MetalLB ha sido instalado y configurado correctamente."