#!/bin/sh

if [ -z "$1" ]; then
    echo "Please provide name for the node"
    exit 1
fi

name=$1
size="${2:-20480}"
network="${3:-wlp3s0}"

VBoxManage createvm --name "${name}" \
  --ostype "Linux_64" --register

VBoxManage modifyvm "${name}" --memory 4096 --cpus 2 --nic1 bridged --bridgeadapter1 "${network}"

VBoxManage storagectl "${name}" --name "IDE Controller" --add ide --controller PIIX4
VBoxManage storageattach "${name}" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "$HOME/Downloads/metal-amd64-v1.11.1.iso"

VBoxManage storagectl "${name}" --name "SATA Controller" --add sata --controller IntelAHCI --portcount 1 --bootable on
VBoxManage createhd --filename "$HOME/VirtualBoxVMs/${name}/${name}.vdi" --size "${size}"
VBoxManage storageattach "${name}" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$HOME/VirtualBoxVMs/${name}/${name}.vdi"
