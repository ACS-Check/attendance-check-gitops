#!/bin/bash

echo "====================================="
echo "Deleting all Kubernetes resources..."
echo "====================================="

# Delete Ingress
echo "Deleting Ingress..."
kubectl delete -f cc-ingress.yaml --ignore-not-found=true

# Delete HPA
echo "Deleting HPA..."
kubectl delete -f cc-nginx-hpa.yaml --ignore-not-found=true
kubectl delete -f cc-tomcat-hpa.yaml --ignore-not-found=true

# Delete Services
echo "Deleting Services..."
kubectl delete -f cc-nginx-svc.yaml --ignore-not-found=true
kubectl delete -f cc-tomcat-svc.yaml --ignore-not-found=true

# Delete Deployments
echo "Deleting Deployments..."
kubectl delete -f cc-nginx-deploy.yaml --ignore-not-found=true
kubectl delete -f cc-tomcat-deploy.yaml --ignore-not-found=true

# Delete ConfigMap
echo "Deleting ConfigMap..."
kubectl delete -f cc-nginx-conf.yaml --ignore-not-found=true

echo "====================================="
echo "All resources deleted successfully!"
echo "====================================="

# Show remaining resources
echo ""
echo "Checking remaining resources..."
kubectl get all -n default
