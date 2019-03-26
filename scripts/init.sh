#!/bin/bash

gcloud version
gcloud init

# prereq
./scripts/01-set-region-zone.sh

# compute resources
./scripts/02-compute-resources.sh

# certificate authority
./scripts/03-certificate-authority.sh

# kubernetes configurations files for auth
./scripts/04-kubernetes-auth-conf-files.sh

# Encryption keys
./scripts/05-encryption-keys.sh

# bootstrapping etcd
./scripts/06-bootstrapping-etcd.sh

# bootstrapping kubernetes controllers
for i in 0 1 2; do
    gcloud compute scp ./scripts/07-bootstrapping-controllers.sh controller-${i}:07-bootstrapping-controllers.sh
    gcloud compute ssh controller-${i} --command "chmod +x 07-bootstrapping-controllers.sh"
    gcloud compute ssh controller-${i} --command "./07-bootstrapping-controllers.sh"
done

# bootstrapping kubernetes workers
for i in 0 1 2; do
    gcloud compute scp ./scripts/08-bootstrapping-workers.sh worker-${i}:08-bootstrapping-workers.sh
    gcloud compute ssh worker-${i} --command "chmod +x 08-bootstrapping-workers.sh"
    gcloud compute ssh worker-${i} --command "./08-bootstrapping-workers.sh"
done

gcloud compute ssh controller-0 \
  --command "kubectl get nodes --kubeconfig admin.kubeconfig"

# configuring kubectl
./scripts/09-configuring-kubectl.sh


