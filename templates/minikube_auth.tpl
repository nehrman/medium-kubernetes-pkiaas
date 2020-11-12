#!/bin/bash

set -e 

export VAULT_SA_NAME=$(kubectl get sa ${service_account} -n default -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -n default -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -n default -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(minikube ip)
vault write -namespace=${vault_namespace} auth/${k8s_backend_path}/config \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="https://$K8S_HOST:8443" \
  kubernetes_ca_cert="$SA_CA_CRT"