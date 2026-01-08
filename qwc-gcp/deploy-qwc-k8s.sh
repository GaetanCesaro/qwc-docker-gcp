# kubectl get po -A
# minilube start
# minikube dashboard
# ... minikube stop

kubectl apply -f atlas-qwc-db-config-configmap.yaml -n default

kubectl apply -f qwc-admin-gui-cm1-configmap.yaml -n default
kubectl apply -f qwc-admin-gui-deployment.yaml -n default

kubectl apply -f qwc-api-gateway-cm0-configmap.yaml -n default
kubectl apply -f qwc-api-gateway-deployment.yaml -n default
kubectl apply -f qwc-api-gateway-service.yaml -n default

kubectl apply -f qwc-auth-service-cm1-configmap.yaml -n default
kubectl apply -f qwc-auth-service-deployment.yaml -n default

kubectl apply -f qwc-config-db-migrate-cm1-configmap.yaml -n default
kubectl apply -f qwc-config-db-migrate-deployment.yaml -n default

kubectl apply -f qwc-config-service-cm1-configmap.yaml -n default
kubectl apply -f qwc-config-service-cm3-configmap.yaml -n default
kubectl apply -f qwc-config-service-cm4-configmap.yaml -n default
kubectl apply -f qwc-config-service-cm5-configmap.yaml -n default
kubectl apply -f qwc-config-service-deployment.yaml -n default

kubectl apply -f qwc-data-service-cm0-configmap.yaml -n default
kubectl apply -f qwc-data-service-cm1-configmap.yaml -n default
kubectl apply -f qwc-data-service-deployment.yaml -n default

kubectl apply -f qwc-document-service-claim2-persistentvolumeclaim.yaml -n default
kubectl apply -f qwc-document-service-cm1-configmap.yaml -n default
kubectl apply -f qwc-document-service-cm3-configmap.yaml -n default
kubectl apply -f qwc-document-service-deployment.yaml -n default