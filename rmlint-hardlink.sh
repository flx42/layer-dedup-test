#!/bin/bash

set -eux

mkdir -p /tmp/rmlint
umount /tmp/rmlint || true
mount -t tmpfs tmpfs /tmp/rmlint

cd /tmp/rmlint

du -sh /mnt/docker/overlay2
ulimit -n 65535
rmlint --threads=64 -v -T df --config=sh:handler=hardlink /mnt/docker/overlay2 >log 2>&1
./rmlint.sh -d >>log 2>&1

sync
du -sh /mnt/docker/overlay2
