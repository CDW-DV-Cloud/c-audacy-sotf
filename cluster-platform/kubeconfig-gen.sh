#!/bin/bash

# Set variables
SA_NAME="vm-administrator"
NAMESPACE="default"
CLUSTER_NAME="audacy-user-cluster"

# Create the service account if it doesn't exist
kubectl create serviceaccount $SA_NAME -n $NAMESPACE

# Create a cluster role binding for the service account
cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${SA_NAME}-binding
subjects:
- kind: ServiceAccount
  name: ${SA_NAME}
  namespace: ${NAMESPACE}
roleRef:
  kind: ClusterRole
  name: cluster-admin  # Adjust this role based on your needs
  apiGroup: rbac.authorization.k8s.io
EOF

# Get the service account token
kubectl create token $SA_NAME -n $NAMESPACE > sa.token

# Generate kubeconfig using gkectl
gkectl create kubeconfig \
    --kubeconfig=sa-kubeconfig \
    --token=$(cat sa.token) \
    --cluster-name=${CLUSTER_NAME}

# Clean up token file
rm sa.token

echo "Kubeconfig file 'sa-kubeconfig' has been generated"