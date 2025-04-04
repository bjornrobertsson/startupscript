#!/usr/bin/env bash

#
# This will add some variants of URLs that will allow containerd (hopefully) to pull from HTTP based local Registry
cat <<EOF | sudo tee /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".registry.mirrors]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker-registry.docker-registry.svc.local:5000"]
    endpoint = ["http://docker-registry.docker-registry.svc.local:5000"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker-direct.local:80"]
    endpoint = ["http://docker-direct.local:80"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.local"]
    endpoint = ["http://docker.local"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."artifactory.local"]
    endpoint = ["http://artifactory.local"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker-direct.local"]
    endpoint = ["http://docker-direct.local"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.2.250:5000"]
    endpoint = ["http://192.168.2.250:5000"]
EOF

sudo pkill -SIGHUP containerd
