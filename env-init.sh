#!/bin/bash

# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 关闭selinux
sed -i 's/enforcing/disabled/' /etc/selinux/config
setenforce 0

# 关闭swap
sed -ri 's/.*swap.*/#&/' /etc/fstab
swapoff -a

# 添加Hosts
cat >> /etc/hosts << EOF

10.10.11.50	C7K0-Master0
10.10.11.51	C7K1-Master1
10.10.11.52	C7K2-Node0
10.10.11.53	C7K3-Node1
10.10.11.54	C7K4-Node2
10.10.11.55	C7K5-Node3
10.10.11.56	C7K6-Node4

EOF

# 设置网桥参数
cat > /etc/sysctl.d/k8s.conf << EOF

net.bridge.bridge-nf-call-ip6tables = 1

net.bridge.bridge-nf-call-iptables = 1

EOF
sysctl --system

# 时间同步
ntpdate 10.10.10.13

# 更新docker的yum源
yum install wget -y
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo

# 安装docker 19.03.13
yum install docker-ce-19.03.13 -y
systemctl start docker

# 配置国内镜像源
cat > /etc/docker/daemon.json << EOF
{

"registry-mirrors": ["https://registry.docker-cn.com"]

}
EOF
systemctl enable docker.service

# 添加k8s阿里云yum源
cat > /etc/yum.repos.d/kubernetes.repo << EOF

[kubernetes]

name=Kubernetes

baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64

enabled=1

gpgcheck=0

repo_gpgcheck=0

gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg

EOF
# 安装kubelet kubeadm kubectl
yum install kubelet-1.19.4 kubeadm-1.19.4 kubectl-1.19.4 -y
systemctl enable kubelet.service

# 重启CentOS
reboot



# Master节点初始化
# kubeadm init --apiserver-advertise-address=10.10.11.50 --image-repository registry.aliyuncs.com/google_containers --kubernetes-version v1.19.4 --service-cidr=10.96.0.0/12 --pod-network-cidr=10.244.0.0/16
# mkdir -p $HOME/.kube
# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Master节点部署网络插件
# wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# kubectl apply -f kube-flannel.yml