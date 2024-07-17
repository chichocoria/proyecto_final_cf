#!/bin/bash

#!/bin/bash

# Verifica si kubectl está instalado
if ! command -v kubectl &> /dev/null
then
    echo "kubectl no está instalado. Por favor, instala kubectl primero."
    exit 1
fi

# Verifica si Helm está instalado
if ! command -v helm &> /dev/null
then
    echo "Helm no está instalado. Por favor, instala Helm primero."
    exit 1
fi

# Agregar el repositorio de Helm para Longhorn
helm repo add longhorn https://charts.longhorn.io
helm repo update

# Crear el espacio de nombres (namespace) para Longhorn
kubectl create namespace longhorn-system

# Instalar Longhorn
helm install longhorn longhorn/longhorn --namespace longhorn-system
sleep 60
# Verificar la instalación
kubectl get pods -n longhorn-system

echo "Longhorn ha sido instalado correctamente."

# Proporcionar instrucciones para acceder a la interfaz de usuario de Longhorn
echo "Para acceder a la interfaz de usuario de Longhorn, expone el servicio de Longhorn UI con el siguiente comando:"
echo "kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80"

echo "Luego, abre tu navegador y ve a http://localhost:8080 para acceder a la interfaz de usuario de Longhorn."