#!/bin/sh

VBoxManage startvm "control-plane" --type headless
VBoxManage startvm "worker-1" --type headless
VBoxManage startvm "worker-2" --type headless
