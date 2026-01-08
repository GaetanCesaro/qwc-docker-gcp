kubectl delete -f atlas-qwc-db-config-configmap.yaml

kubectl delete -f qwc-admin-gui-deployment.yaml

kubectl delete -f atlas-qwc-api-gateway-config-configmap.yaml
kubectl delete -f qwc-api-gateway-deployment.yaml
kubectl delete -f qwc-api-gateway-service.yaml

kubectl delete -f qwc-auth-service-deployment.yaml

kubectl delete -f atlas-qwc-config-db-migrate-demo-data-config-configmap.yaml
kubectl delete -f qwc-config-db-migrate-deployment.yaml