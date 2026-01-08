kubectl delete -f atlas-qwc-db-config-configmap.yaml

kubectl delete -f qwc-admin-gui-cm1-configmap.yaml
kubectl delete -f qwc-admin-gui-deployment.yaml

kubectl delete -f qwc-api-gateway-cm0-configmap.yaml
kubectl delete -f qwc-api-gateway-deployment.yaml
kubectl delete -f qwc-api-gateway-service.yaml

kubectl delete -f qwc-auth-service-cm1-configmap.yaml
kubectl delete -f qwc-auth-service-deployment.yaml

kubectl delete -f qwc-config-db-migrate-cm1-configmap.yaml
kubectl delete -f qwc-config-db-migrate-deployment.yaml