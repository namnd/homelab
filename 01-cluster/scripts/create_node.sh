#!/bin/sh

# Generic function to create a VirtualBox VM
create_vm() {
  local name=$1
  local size=${2:-20480}      # Default size in MB
  local network=${3:-wlp3s0}  # Default network interface
  local memory=${4:-4096}     # Default memory in MB
  local cpus=${5:-2}          # Default CPUs

  local iso_path="$HOME/Downloads/metal-amd64-v1.11.1.iso"  # Hardcoded ISO path
  local data_path="/data/VirtualBoxVMs/"

  echo "Creating VM: $name with size ${size}MB, memory ${memory}MB, CPUs $cpus, network $network"

  VBoxManage createvm --name "${name}" --ostype "Linux_64" --register

  VBoxManage modifyvm "${name}" --memory "$memory" --cpus "$cpus" --nic1 bridged --bridgeadapter1 "${network}"

  VBoxManage storagectl "${name}" --name "IDE Controller" --add ide --controller PIIX4
  VBoxManage storageattach "${name}" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "${iso_path}"

  VBoxManage storagectl "${name}" --name "SATA Controller" --add sata --controller IntelAHCI --portcount 1 --bootable on
  VBoxManage createhd --filename "${data_path}/${name}/${name}.vdi" --size "${size}"
  VBoxManage storageattach "${name}" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "${data_path}/${name}/${name}.vdi"
}

# Create control plane node
create_vm "control-plane" 20480
# Create worker nodes
create_vm "worker-1" 102400
create_vm "worker-2" 102400
