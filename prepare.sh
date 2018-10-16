#!/bin/bash

set -eux

instance_type=$(curl -fsSL 'http://169.254.169.254/latest/meta-data/instance-type')
if [ "${instance_type}" != "i3.16xlarge" ]; then
    echo "Not an i3.16xlarge instance, aborting."
    exit 1
fi

systemctl stop docker || true
umount /mnt/docker || true

# Prepare storage (RAID 0)
storage="/dev/md0"
mdadm --stop "${storage}" || true
mdadm --remove "${storage}" || true
mdadm --create --verbose "${storage}" --level=0 --raid-devices=8 /dev/nvme{0..7}n1

fstype="ext4"
mkfs.${fstype} "${storage}"
mkdir -p /mnt/docker
mount -t "${fstype}" "${storage}" /mnt/docker

# Prepare docker configuration
mkdir -p /etc/systemd/system/docker.service.d
cat <<EOF | tee /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --host=fd:// --storage-driver=overlay2 --data-root=/mnt/docker --max-concurrent-downloads=64
EOF

# Install docker-ce
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce
systemctl daemon-reload
systemctl restart docker

# Install dedup tools
apt-get install -y duperemove restic rmlint borgbackup

# Install misc tools
apt-get install -y parallel jq
