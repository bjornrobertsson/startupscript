#!/usr/bin/env bash

CONFIG_FILE="/etc/containerd/config.toml"

# Ensure the config file exists
sudo touch "$CONFIG_FILE"

# Function to append a mirror config block if it doesn't exist
add_mirror_block() {
  local registry="$1"
  local url="$2"

  if ! grep -q "$registry" "$CONFIG_FILE"; then
    echo "Adding mirror for $registry"
    sudo tee -a "$CONFIG_FILE" > /dev/null <<EOF

[plugins."io.containerd.grpc.v1.cri".registry.mirrors."$registry"]
  endpoint = ["$url"]
EOF
  else
    echo "Mirror for $registry already exists, skipping."
  fi
}

# Add mirrors
add_mirror_block "docker-registry.docker-registry.svc.local:5000" "http://docker-registry.docker-registry.svc.local:5000"
add_mirror_block "docker-direct.local:80" "http://docker-direct.local:80"
add_mirror_block "docker.local" "http://docker.local"
add_mirror_block "artifactory.local" "http://artifactory.local"
add_mirror_block "docker-direct.local" "http://docker-direct.local"
add_mirror_block "192.168.2.250:5000" "http://192.168.2.250:5000"


sudo pkill -SIGHUP containerd
