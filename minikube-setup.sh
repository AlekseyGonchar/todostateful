#!/usr/bin/bash

set -euxo pipefail -c

minikube start \
    --driver=docker \
    --addons=dashboard \
    --addons=default-storageclass \
    --addons=ingress \
    --addons=ingress-dns \
    --addons=logviewer \
    --addons=metrics-server \
    --addons=storage-provisioner \
    --addons=registry

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml

eval "$(minikube docker-env)"

docker build . --tag=todostateful:latest

kubectl apply -f kubernetes.yaml
