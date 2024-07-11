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
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Crear el espacio de nombres (namespace) para Longhorn
kubectl create namespace monitoring

##Instala kube-prom-stack
helm install monitoring-prometheus-stack prometheus-community/kube-prometheus-stack --version 49.2.0 --namespace monitoring -f ~/proyecto_final_cf/k8s/kube-prom-stack/instalar-longhorn-helm.sh

sleep 60

##Instala loki-stack con persistencia de datos
helm install loki --namespace=monitoring grafana/loki-stack \
  --namespace monitoring --set loki.image.tag=2.9.3 \
  --set loki.persistence.enabled=true \
  --set loki.persistence.storageClassName=longhorn \
  --set loki.persistence.size=5Gi \
  --set 'promtail.tolerations[0].key=CriticalAddonsOnly' \
  --set 'promtail.tolerations[0].operator=Exists' \
  --set 'promtail.tolerations[0].effect=NoExecute' \
  --set 'promtail.tolerations[1].key=node-role.kubernetes.io/control-plane' \
  --set 'promtail.tolerations[1].operator=Exists' \
  --set 'promtail.tolerations[1].effect=NoSchedule'

sleep 10

# Proporcionar instrucciones para acceder a la interfaz de usuario de Longhorn
echo "Para acceder a la interfaz de usuario de Longhorn, expone el servicio de Longhorn UI con el siguiente comando:"
echo "kubectl port-forward service/monitoring-prometheus-stack-grafana 9000:80 -n monitoring"
echo "Luego, abre tu navegador y ve a http://localhost:9000 para acceder a la interfaz de usuario de grafana."
echo "user:admin"
echo "pass: prom-operator"