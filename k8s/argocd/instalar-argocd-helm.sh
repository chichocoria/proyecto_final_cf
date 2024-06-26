#!/bin/bash

# Verifica si Helm está instalado
if ! command -v helm &> /dev/null
then
    echo "Helm no está instalado. Por favor, instala Helm primero."
    exit 1
fi

## 1 - Create a namespace for ArgoCD:
kubectl create namespace argocd

## 2 - Install the ArgoCD Helm chart:
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace argocd
sleep 30
## 3 - Verify that ArgoCD is running:
kubectl get pods -n argocd

## 4 - En nuestro caso vamos a exponer argo server al loadBalancer con este comando, asi nos da una IP externa de MetallB para acceder
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Obtener la contraseña inicial del usuario admin
echo "La contraseña inicial del usuario admin es:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d