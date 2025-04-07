#!/usr/bin/env bash

CONFIG_FILE="/etc/containerd/config.toml"

# Ensure the config file exists
sudo touch "$CONFIG_FILE"

# Function to safely add a mirror block
add_mirror_block() {
  local registry="$1"
  local url="$2"
  local insecure="$3"

  if grep -q "\[plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"$registry\"\]" "$CONFIG_FILE"; then
    echo "Mirror for $registry already exists. Skipping."
    return
  fi

  echo "Adding mirror for $registry"

  sudo tee -a "$CONFIG_FILE" > /dev/null <<EOF

[plugins."io.containerd.grpc.v1.cri".registry.mirrors."$registry"]
  endpoint = ["$url"]
EOF

  # Optional: Add insecure_skip_verify if requested
  if [ "$insecure" = "true" ]; then
    sudo tee -a "$CONFIG_FILE" > /dev/null <<EOF
[plugins."io.containerd.grpc.v1.cri".registry.configs."$registry".tls]
  insecure_skip_verify = true
EOF
  fi
}

# ---- Registry Mirror List ----
add_mirror_block "docker-registry.docker-registry.svc.local:5000" "http://docker-registry.docker-registry.svc.local:5000"
add_mirror_block "docker-direct.local:80" "http://docker-direct.local:80"
add_mirror_block "docker.local" "https://docker.local" true
add_mirror_block "artifactory.local" "http://artifactory.local"
add_mirror_block "docker-direct.local" "http://docker-direct.local"
add_mirror_block "192.168.2.250:5000" "http://192.168.2.250:5000"

echo "Done patching $CONFIG_FILE"

sudo pkill -SIGHUP containerd
