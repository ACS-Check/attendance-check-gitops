#!/bin/bash

echo "====================================="
echo "Deploying all Kubernetes resources..."
echo "====================================="

# Create namespaces
echo "Creating namespaces..."
kubectl get namespace cc-frontend >/dev/null 2>&1 || kubectl create namespace cc-frontend
kubectl get namespace cc-backend >/dev/null 2>&1 || kubectl create namespace cc-backend

# Apply ConfigMap
echo "Applying ConfigMap..."
kubectl apply -f cc-nginx-conf.yaml

# Apply Deployments
echo "Applying Deployments..."
kubectl apply -f cc-nginx-deploy.yaml
kubectl apply -f cc-tomcat-deploy.yaml

# Apply Services
echo "Applying Services..."
kubectl apply -f cc-nginx-svc.yaml
kubectl apply -f cc-tomcat-svc.yaml

# Apply HPA
echo "Applying HPA..."
kubectl apply -f cc-nginx-hpa.yaml
kubectl apply -f cc-tomcat-hpa.yaml

# Apply Ingress
echo "Applying Ingress..."
kubectl apply -f cc-ingress.yaml

echo "====================================="
echo "All resources deployed successfully!"
echo "====================================="

# Show deployed resources
echo ""
echo "Checking deployed resources..."
kubectl get all -n default
kubectl get ingress -n default
