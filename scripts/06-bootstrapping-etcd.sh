#!/bin/bash

for i in 0 1 2; do
  gcloud compute ssh controller-${i} --command "wget -q --show-progress --https-only --timestamping \
    \"https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz\""
  gcloud compute ssh controller-${i} --command "tar -xvf etcd-v3.3.9-linux-amd64.tar.gz"
  gcloud compute ssh controller-${i} --command "mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/"
done

for i in 0 1 2; do
    gcloud compute ssh controller-${i} --command "mkdir -p /etc/etcd /var/lib/etcd"
    gcloud compute ssh controller-${i} --command "cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/"
done


for i in 0 1 2; do
    INTERNAL_IP=$(gcloud compute ssh controller-${i} --command "curl -s -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
    ETCD_NAME=$(gcloud compute ssh controller-${i} --command "hostname -s")
    cat <<EOF | tee ./etcd.service.controller-${i}
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-0=https://10.240.0.10:2380,controller-1=https://10.240.0.11:2380,controller-2=https://10.240.0.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    gcloud compute scp ./etcd.service.controller-${i} controller-${i}:/etc/systemd/system/etcd.service
done


for i in 0 1 2; do
    gcloud compute ssh controller-${i} --command "sudo systemctl daemon-reload"
    gcloud compute ssh controller-${i} --command "sudo systemctl enable etcd"
    gcloud compute ssh controller-${i} --command "sudo systemctl start etcd"
done

for i in 0 1 2; do
    gcloud compute ssh controller-${i} --command "sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem"

done
