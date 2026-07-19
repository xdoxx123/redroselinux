#!/bin/bash

#set -x

# ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
# ----


tools=(curl jq wget qemu-system-x86_64 qemu-img)
MISSING=0

iso_path=~/.cache/redrose.iso
drive_path=~/.cache/redrose.qcow2

download_url () {
    echo -e "${GREEN}[!] Downloading : $1${NC}"
if [ -f "$iso_path" ]; then
    rm "$iso_path"
fi
if [ -f "$drive_path" ]; then
    rm "$drive_path"
fi
  qemu-img create -q -f qcow2 $drive_path 2G
  wget -q --show-progress -O $iso_path $1
  echo -e "${YELLOW}[!] Running the VM${NC}"
  qemu-system-x86_64 -enable-kvm -cpu host -m 2G \
              -nic user,model=virtio \
              -hda $drive_path \
             -cdrom $iso_path

}


for t in "${tools[@]}"; do
    if ! command -v "$t" &>/dev/null; then
        echo -e "${RED}[!!!] missing: ${NC} $t"
        MISSING=1
    fi
done
if [ "$MISSING" = 1 ]; then
    exit
fi

mkdir -p ~/.cache

echo -e "${GREEN}Downloading the manifest... ${NC}"
res=$(curl -s -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2026-03-10" https://api.github.com/repos/redroselinux/redroselinux/releases)
versions=$(echo "$res" | jq ".[].name")
index=0
versions_table=()
# jq .[].assets.[].browser_download_url
while IFS= read -r line; do
    versions_table+=("$line")
    ((index=index+1))
    trim=$(echo "$line" | tr -d '"\\')
    #versions
    echo "$index - $trim"
done <<< "$versions"

read -p "Which version to download? (1) -> " answer


if [ "$answer" = "" ]; then
    url=$(echo "$res" | jq -r ".[0].assets.[].browser_download_url")
    download_url $url
elif [[ "$answer" =~ ^[0-9]+$ ]] && [ "$answer" -le $((index)) ]; then

    url=$(echo "$res" | jq -r ".[$((answer - 1))].assets.[].browser_download_url")
    download_url $url
else
    echo "Wrong input"
    exit
fi
