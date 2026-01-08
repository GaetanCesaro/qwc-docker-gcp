# kubectl get po -A
# minilube start
# minikube dashboard
# ... minikube stop

kubectl apply -f atlas-qwc-db-config-configmap.yaml -n default

kubectl apply -f qwc-admin-gui-deployment.yaml -n default

kubectl apply -f atlas-qwc-api-gateway-config-configmap.yaml -n default
kubectl apply -f qwc-api-gateway-deployment.yaml -n default
kubectl apply -f qwc-api-gateway-service.yaml -n default

kubectl apply -f qwc-auth-service-deployment.yaml -n default

kubectl apply -f atlas-qwc-config-db-migrate-demo-data-config-configmap.yaml -n default
kubectl apply -f qwc-config-db-migrate-deployment.yaml -n default

kubectl apply -f atlas-qwc-folder-config-out-configmap.yaml -n default
kubectl apply -f atlas-qwc-qgis-ressources-config-configmap.yaml -n default
kubectl apply -f atlas-qwc-print-layouts-config-configmap.yaml -n default
kubectl apply -f atlas-qwc-report-config-configmap.yaml -n default
kubectl apply -f qwc-config-service-deployment.yaml -n default

kubectl apply -f atlas-qwc-folder-attachments-configmap.yaml -n default
kubectl apply -f qwc-data-service-deployment.yaml -n default

kubectl apply -f atlas-qwc-volume-read-write-once-persistentvolumeclaim.yaml -n default
kubectl apply -f atlas-qwc-report-config-configmap.yaml -n default
kubectl apply -f qwc-document-service-deployment.yaml -n default