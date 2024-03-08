#!/usr/bin/env bash

# Required:
# - unzip

# Kali
# https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-qemu-amd64.7z

# qemu-img ?
# qemu-img convert -O qcow2 in.iso out.qcow2

# unzip *


qemu-system-x86_64 \
-drive file=./qemu/kali.qcow2,format=qcow2 \
-drive file=./qemu/metasploitable.qcow2,format=qcow2
-bios /run/libvirt/nix-ovmf/OVMF_CODE.fd
-boot menu=on
