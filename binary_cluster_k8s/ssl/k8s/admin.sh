#!/bin/sh
#

export KUBE_APISERVER="https://k8sapi:6443"

# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/k8s/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER}

# 设置客户端认证参数
kubectl config set-credentials admin \
  --client-certificate=./admin.pem \
  --embed-certs=true \
  --client-key=./admin-key.pem

# 设置上下文参数
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin

# 设置默认上下文
kubectl config use-context kubernetes


