#!/bin/bash
#

DNS_SERVER_IP=${1:-"10.96.0.10"}
HOSTNAME=${2:-"`hostname`"}
CLUSTERDOMAIN=${3:-"cluster.local"}

cat <<EOF >/opt/kubernetes/cfg/kubelet.conf
KUBELET_OPTS="--logtostderr=true \\
--v=2 \\
--hostname-override=${HOSTNAME} \\
--kubeconfig=/opt/kubernetes/cfg/kubelet.kubeconfig \\
--bootstrap-kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig \\
--config=/opt/kubernetes/cfg/kubelet-config.yml \\
--cert-dir=/opt/kubernetes/ssl/k8s \\
--network-plugin=cni \\
--cni-conf-dir=/etc/cni/net.d \\
--cni-bin-dir=/opt/cni/bin \\
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2"
EOF

cat <<EOF >/opt/kubernetes/cfg/kubelet-config.yml
kind: KubeletConfiguration  # 使用对象
apiVersion: kubelet.config.k8s.io/v1beta1   # api版本
address: 0.0.0.0    # 监听地址
port: 10250 # 当前kubelet的端口
readOnlyPort: 10255 # kubelet暴露的端口
cgroupDriver: systemd  # 驱动，要与docker info显示的一致
clusterDNS:
  - ${DNS_SERVER_IP}
clusterDomain: ${CLUSTERDOMAIN} # 集群域
failSwapOn: false   # 关闭swap


# 身份验证
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 2m0s
    enabled: true
  x509:
    clientCAFile: /opt/kubernetes/ssl/k8s/ca.pem


# 授权
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s

# Node 资源保留
evictionHard:
  imagefs.available: 15%
  memory.available: 1G
  nodefs.available: 10%
  nodefs.inodesFree: 5%
evictionPressureTransitionPeriod: 5m0s

# 镜像删除策略
imageGCHighThresholdPercent: 85
imageGCLowThresholdPercent: 80
imageMinimumGCAge: 2m0s

# 旋转证书
rotateCertificates: true    # 旋转kubelet client证书
featureGates:
  RotateKubeletServerCertificate: true
  RotateKubeletClientCertificate: true

maxOpenFiles: 1000000
maxPods: 110
EOF

cat <<EOF >/usr/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kubelet.conf
ExecStart=/opt/kubernetes/bin/kubelet \$KUBELET_OPTS
Restart=on-failure
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kubelet
systemctl restart kubelet
