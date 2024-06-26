##Antes de instalar Cert-Manager en su clúster a través de Helm, creará un espacio de nombres para él:
kubectl create namespace cert-manager

##Deberá agregar el repositorio Jetstack Helm a Helm, que aloja el gráfico Cert-Manager. Para hacer esto, ejecute el siguiente comando:
helm repo add jetstack https://charts.jetstack.io

##Actualizar helm
helm repo update

##Finalmente, instale Cert-Manager en el cert-managerespacio de nombres ejecutando el siguiente comando:
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.12.3 --set installCRDs=true
sleep 30
##Despliégalo con kubectl:
kubectl apply -f ~/proyecto_final_cf/k8s/cert-manager/production_issuer.yaml

