#!/usr/bin/env bash

set -e

helm uninstall kong -n kong || true

kubectl delete namespace kong --wait=false || true

kubectl delete clusterrole kong-kong || true
kubectl delete clusterrolebinding kong-kong || true
kubectl delete validatingwebhookconfiguration kong-kong-validations || true
kubectl delete ingressclass kong || true

kubectl delete crd $(kubectl get crd | awk '/konghq.com/{print $1}') || true