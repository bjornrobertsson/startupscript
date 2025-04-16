#!/usr/bin/env bash

CONFIG_FILE="/etc/containerd/config.toml"
PAGER=cat

# Ensure the config file exists
sudo touch "$CONFIG_FILE"

add_mirror_block() {
  local registry="$1"
  local url="$2"
  local insecure="$3"

  local certs_dir="/etc/containerd/certs.d/$registry"
  local hosts_file="$certs_dir/hosts.toml"

  if [ -f "$hosts_file" ]; then
    echo "hosts.toml for $registry already exists. Skipping."
    return
  fi

  echo "Creating mirror config for $registry in $hosts_file"

  sudo mkdir -p "$certs_dir"

  sudo tee "$hosts_file" > /dev/null <<EOF
server = "$url"

[host."$url"]
  capabilities = ["pull", "resolve"]
EOF

  if [ "$insecure" = "true" ]; then
    sudo tee -a "$hosts_file" > /dev/null <<EOF
  skip_verify = true
EOF
  fi

  sleep 10
  systemctl restart containerd
  sleep 2
  systemctl status containerd |tail -10
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

add_mirror_block "docker-registry.docker-registry.svc.local:5000" "http://docker-registry.docker-registry.svc.local:5000" || revert_toml
add_mirror_block "docker-registry.docker-registry.svc.local:5000" "http://docker-registry.docker-registry.svc.local:5000" || revert_toml
add_mirror_block "docker-direct.local:80" "http://docker-direct.local:80" || revert_toml
add_mirror_block "docker.local" "https://docker.local" true || revert_toml
add_mirror_block "artifactory.local" "http://artifactory.local" || revert_toml
add_mirror_block "docker-direct.local" "http://docker-direct.local" || revert_toml
add_mirror_block "192.168.2.250:5000" "http://192.168.2.250:5000" || revert_toml

echo "Done patching $CONFIG_FILE"

### sudo pkill -SIGHUP contained

systemctl restart containerd
