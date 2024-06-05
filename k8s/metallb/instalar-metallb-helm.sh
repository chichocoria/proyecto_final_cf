#!/bin/bash

#1 - Agregar MetalLB al respositorio de Helm
helm repo add metallb https://metallb.github.io/metallb
#2 - Hacer un update del repo
helm repo update
#3 - Crear el namespace
kubectl create namespace metallb
#4 - Install metalLB en el namespace metallb
helm install metallb metallb/metallb --namespace metallb