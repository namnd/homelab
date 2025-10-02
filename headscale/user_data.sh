#!/bin/bash

wget https://github.com/juanfont/headscale/releases/download/v0.26.1/headscale_0.26.1_linux_amd64.deb

sudo apt install ./headscale_0.26.1_linux_amd64.deb

sudo mv /etc/headscale/config.yaml /etc/headscale/config.yaml.original

sudo echo ${headscale_config_base64} | base64 --decode > /etc/headscale/config.yaml

sudo systemctl enable --now headscale
