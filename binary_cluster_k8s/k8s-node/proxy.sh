#!/bin/bash
#

HOSTNAME=${1:-"`hostname`"}

cat <<EOF >/opt/kubernetes/cfg/kube-proxy.conf
KUBE_PROXY_OPTS="--logtostderr=true \\
--v=2 \\
--config=/opt/kubernetes/cfg/kube-proxy-config.yml"
EOF

cat <<EOF >/opt/kubernetes/cfg/kube-proxy-config.yml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
address: 0.0.0.0    # 监听地址
metricsBindAddress: 0.0.0.0:10249
clientConnection:
  kubeconfig: /opt/kubernetes/cfg/kube-proxy.kubeconfig # 读取配置文件
hostnameOverride: ${HOSTNAME}   # 注册到k8s的节点名称唯一
clusterCIDR: 10.96.0.0/12   # service IP范围
mode: ipvs  # 使用ipvs模式
ipvs:
  scheduler: "rr"

# 使用iptables模式
# mode: iptables
# iptables:
#   masqueradeAll: true
EOF

cat <<EOF >/usr/lib/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-proxy.conf
ExecStart=/opt/kubernetes/bin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-proxy
systemctl restart kube-proxy

