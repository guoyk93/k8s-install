#!/usr/bin/env python3

import os

image_names = (
    'k8s.gcr.io/kube-apiserver:v1.17.4',
    'k8s.gcr.io/kube-controller-manager:v1.17.4',
    'k8s.gcr.io/kube-scheduler:v1.17.4',
    'k8s.gcr.io/kube-proxy:v1.17.4',
    'k8s.gcr.io/pause:3.1',
    'k8s.gcr.io/etcd:3.4.3-0',
    'k8s.gcr.io/coredns:1.6.5',
    'quay.io/coreos/flannel:v0.12.0-amd64',
    'quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.30.0',
    'jettech/kube-webhook-certgen:v1.0.0',
    'k8s.gcr.io/defaultbackend-amd64:1.5',
    'quay.io/jetstack/cert-manager-controller:v0.14.1',
    'quay.io/jetstack/cert-manager-webhook:v0.14.1',
    'quay.io/jetstack/cert-manager-cainjector:v0.14.1',
)

registry = 'registry.cn-beijing.aliyuncs.com/landzero-k8s'

for image_name in image_names:
    print('------------------')
    print(f'Image: {image_name}')
    splits = image_name.split('/')
    base_name = splits[len(splits)-1]
    print(f'BaseName: {base_name}')
    mirror_name = registry+'/'+base_name
    print(f'MirrorName: {mirror_name}')
    os.system(f'docker pull {image_name}')
    os.system(f'docker tag {image_name} {mirror_name}')
    os.system(f'docker push {mirror_name}')
