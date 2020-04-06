#!/bin/bash

set -eu

KI_DOCKER_VERSION=19.03.8
KI_KUBERNETES_VERSION=1.17.4

# Kernel Modules

cat <<-EOF

=== Enable Kernel Modules

EOF

KI_KERNEL_MODULES=( br_netfilter ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh nf_conntrack_ipv4 )
KI_KERNEL_MODULES_FILE=/etc/modules-load.d/k8s-install.conf

rm -f "${KI_KERNEL_MODULES_FILE}"

for MODULE_NAME in "${KI_KERNEL_MODULES[@]}"; do
echo "* ${MODULE_NAME}"
modprobe "${MODULE_NAME}"
echo "${MODULE_NAME}" >> ${KI_KERNEL_MODULES_FILE}
done

echo
echo "${KI_KERNEL_MODULES_FILE} Updated"

# sysctl.conf

cat <<-EOF

=== Update sysctl.conf

EOF

KI_SYSCTL_FILE=/etc/sysctl.d/k8s-install.conf

cat <<-EOF > ${KI_SYSCTL_FILE}
net.ipv4.ip_forward = 1

net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system &> /dev/null

echo "${KI_SYSCTL_FILE} Updated"

# Yum Repos

cat <<-EOF

=== Update Yum Repositories

EOF

KI_YUM_REPO_FILE=/etc/yum.repos.d/k8s-install.repo

cat <<-EOF > ${KI_YUM_REPO_FILE}
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

echo "${KI_YUM_REPO_FILE} Updated"
echo

yum makecache -y

# Disable firewalld

cat <<-EOF

=== Disable firewalld

EOF

systemctl disable --now firewalld

# Disable SELinux

cat <<-EOF

=== Disable SELinux

EOF

setenforce 0 || true
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Install Packages

cat <<-EOF

=== Install Packages

EOF

yum install -y yum-plugin-versionlock \
    ipset \
    ipvsadm \
    docker-ce-${KI_DOCKER_VERSION} \
    docker-ce-cli-${KI_DOCKER_VERSION} \
    kubelet-${KI_KUBERNETES_VERSION} \
    kubeadm-${KI_KUBERNETES_VERSION} \
    kubectl-${KI_KUBERNETES_VERSION}

yum versionlock docker-ce kubelet kubeadm kubectl

# Configure Docker

cat <<-EOF

=== Configure Docker

EOF

mkdir -p /etc/docker

KI_DOCKER_DAEMON_FILE=/etc/docker/daemon.json

if [ ! -f "${KI_DOCKER_DAEMON_FILE}" ]; then

cat <<-EOF > /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

echo "${KI_DOCKER_DAEMON_FILE} Created"

else

echo "${KI_DOCKER_DAEMON_FILE} Existed"

fi

# Information

cat <<-EOF
==========================================

Installed:

    docker
    kubeadm
    kubelet
    kubectl

==========================================

== Suggested Commands

* Enable and Start Docker

    systemctl enable --now docker

* Enable kubelet

    systemctl enable kubelet

* Initialize Kubernetes

    * Single Node

    kubeadm init --config config/kubeadm.yml

    * HA

    Enable 'controlPlaneEndpoint' in config/kubeadm.yml and run

    kubeadm init --config config/kubeadm.yml --upload-certs

* Install kubeconfig

    mkdir -p $HOME/.kube
    cp -f /etc/kubernetes/admin.conf $HOME/.kube/config

* Install Flannel

    kubectl apply -f lib/kube-flannel.yml

* Tear-down and Clean Up Kubernetes

    kubectl delete node [NODE_NAME]
    kubeadm reset
    iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
    ipvsadm -C

EOF
