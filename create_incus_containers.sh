#!/bin/sh
set -eu

if [ $# -ne 1 ]; then
  >&2 echo Usage: $0 project_name
  exit 2
fi

project_name="$1"
container_names="clickhouse01 clickhouse02 keeper01 keeper02 keeper03"

project_ssh_dir=ssh
root_password="proxy-santos-hatch-plotting"

ssh_known_hosts="$project_ssh_dir/known_hosts"
ssh_config="$project_ssh_dir/config"
private_key="$project_ssh_dir/id_ed25519.$project_name"
public_key="${private_key}.pub"

create_container() {
  container_name="$1"
  
  if incus info "$container_name" 2>/dev/null >/dev/null; then
    return
  fi

  incus launch images:ubuntu/24.04 "$container_name" --network noipv6
  incus exec "$container_name" -- apt update
  incus exec "$container_name" -- apt -y install openssh-server
  incus exec "$container_name" -- mkdir -p -m 700 /root/.ssh
  echo "root:$root_password" | incus exec "$container_name" -- chpasswd root
  incus file push --uid 0 --gid 0 "$public_key" "$container_name/root/.ssh/authorized_keys"
  incus exec "$container_name" -- chmod 600 /root/.ssh/authorized_keys
  
  ipv4_addr=$(incus list -c 4 -f csv "^${container_name}\$" | cut -d ' ' -f 1)
  
  ssh-keyscan "$ipv4_addr" >> "$ssh_known_hosts" 2> /dev/null
  
  if [ -f "$ssh_config" ]; then
    sed -i "/^Host $container_name$/,/^$/d" "$ssh_config"
  fi
  
  cat <<EOF >> "$ssh_config"
Host $container_name
  Hostname $ipv4_addr
  User root
  ForwardAgent yes
  UserKnownHostsFile $ssh_known_hosts
  IdentityFile $private_key

EOF
}
  
if [ ! -f "$public_key" ]; then
  mkdir -p "$project_ssh_dir"
  ssh-keygen -t ed25519 -C "key for $project_name incus project" -N '' -f "$private_key"
fi

if ! incus network info noipv6 2>/dev/null >/dev/null; then
  incus network create noipv6 ipv6.address=none
fi

if ! incus project info "$project_name" 2>/dev/null >/dev/null; then
  incus project create "$project_name"
  incus profile show default --project default | incus profile edit --project "$project_name" default
fi

incus project switch "$project_name"

for container in $container_names; do
  create_container "$container"
done
