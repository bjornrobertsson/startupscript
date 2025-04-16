#!/usr/bin/env bash

CONFIG_FILE="/etc/containerd/config.toml"
PAGER=cat

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
 sleep 10
 systemctl restart containerd
 sleep 2
 systemctl status containerd
 return $?
}

backup_toml() {
 # Backup original config
 if [ ! -f "$BACKUP_TOML" ]; then
    cp "$CONTAINERD_TOML" "$BACKUP_TOML"
 fi
}

revert_toml() {
    echo "Reverting containerd config..."
    cp "$BACKUP_TOML" "$CONTAINERD_TOML"
    systemctl restart containerd
    if systemctl is-active --quiet containerd; then
        echo "containerd successfully reverted and running."
	exit 0
    else
        echo "containerd failed to start even after reverting. Manual intervention needed."
    fi
}
# ---- Registry Mirror List ----

CONTAINERD_TOML="/etc/containerd/config.toml"
BACKUP_TOML="/etc/containerd/config.toml.bak"

backup_toml

# add_mirror_block "docker-registry.docker-registry.svc.local:5000" "http://docker-registry.docker-registry.svc.local:5000" || revert_toml
add_mirror_block "docker-registry.docker-registry.svc.local:5000" "http://docker-registry.docker-registry.svc.local:5000" || revert_toml
add_mirror_block "docker-direct.local:80" "http://docker-direct.local:80" || revert_toml
add_mirror_block "docker.local" "https://docker.local" true || revert_toml
add_mirror_block "artifactory.local" "http://artifactory.local" || revert_toml
add_mirror_block "docker-direct.local" "http://docker-direct.local" || revert_toml
add_mirror_block "192.168.2.250:5000" "http://192.168.2.250:5000" || revert_toml

echo "Done patching $CONFIG_FILE"

### sudo pkill -SIGHUP contained

systemctl restart containerd
