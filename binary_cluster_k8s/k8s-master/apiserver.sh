#!/bin/bash

MASTER_ADDRESS=${1:-"172.17.19.209"}
ETCD_SERVERS=${2:-"http://127.0.0.1:2379"}

cat <<EOF >/opt/kubernetes/cfg/kube-apiserver
KUBE_APISERVER_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/var/log/kubernetes \\
--etcd-servers=${ETCD_SERVERS} \\
--bind-address=0.0.0.0 \\
--secure-port=6443 \\
--advertise-address=${MASTER_ADDRESS} \\
--allow-privileged=true \\
--service-cluster-ip-range=10.96.0.0/12 \\
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,NodeRestriction \\
--authorization-mode=RBAC,Node \\
--kubelet-https=true \\
--enable-bootstrap-token-auth=true \\
--token-auth-file=/opt/kubernetes/cfg/token.csv \\
--service-node-port-range=30000-50000 \\
--kubelet-client-certificate=/opt/kubernetes/ssl/k8s/server.pem \\
--kubelet-client-key=/opt/kubernetes/ssl/k8s/server-key.pem \\
--tls-cert-file=/opt/kubernetes/ssl/k8s/server.pem  \\
--tls-private-key-file=/opt/kubernetes/ssl/k8s/server-key.pem \\
--client-ca-file=/opt/kubernetes/ssl/k8s/ca.pem \\
--service-account-key-file=/opt/kubernetes/ssl/k8s/ca-key.pem \\
--etcd-cafile=/opt/kubernetes/ssl/etcd/ca.pem \\
--etcd-certfile=/opt/kubernetes/ssl/etcd/server.pem \\
--etcd-keyfile=/opt/kubernetes/ssl/etcd/server-key.pem \\
--requestheader-client-ca-file=/opt/kubernetes/ssl/k8s/ca.pem \\
--requestheader-extra-headers-prefix=X-Remote-Extra- \\
--requestheader-group-headers=X-Remote-Group \\
--requestheader-username-headers=X-Remote-User \\
--proxy-client-cert-file=/opt/kubernetes/ssl/k8s/metrics-server.pem \\
--proxy-client-key-file=/opt/kubernetes/ssl/k8s/metrics-server-key.pem \\
--runtime-config=api/all=true \\
--audit-log-maxage=30 \\
--audit-log-maxbackup=3 \\
--audit-log-maxsize=100 \\
--audit-log-truncate-enabled=true \\
--audit-log-path=/var/log/kubernetes/k8s-audit.log"
EOF

cat <<EOF >/usr/lib/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-apiserver
ExecStart=/opt/kubernetes/bin/kube-apiserver \$KUBE_APISERVER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-apiserver
systemctl restart kube-apiserver
