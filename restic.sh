#!/bin/bash

set -eux

export RESTIC_REPOSITORY="/tmp/restic"
export RESTIC_PASSWORD="password"

umount "${RESTIC_REPOSITORY}" || true
mkdir -p "${RESTIC_REPOSITORY}"
mount -t tmpfs -o size=90% tmpfs "${RESTIC_REPOSITORY}"

restic init
restic backup /mnt/docker/overlay2

du -sh "${RESTIC_REPOSITORY}"
