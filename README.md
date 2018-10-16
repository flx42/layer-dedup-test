# layer-dedup-test

This repository contains a few simple scripts to test different deduplication strategies on docker layers.
These scripts are meant to be executed on a AWS `i3.16xlarge` instance with 8 NVMe SSDs and running Ubuntu 18.04.

## [`prepare.sh`](https://github.com/flx42/layer-dedup-test/blob/master/prepare.sh)

* Verify if the machine is an AWS instance of type `i3.16xlarge` (I don't want to overwrite your NVMe disks).
* Setup a RAID 0 array with the 8 NVMe SSDs using `mdadm`.
* Create a `ext4` filesystem on the array (`btrfs` had performance problems and `xfs` crashed).
* Mount the created filesystem on `/mnt/docker`.
* Install Docker CE and configure the daemon with `--storage-driver=overlay2 --data-root=/mnt/docker`.

## [`pull.sh`](https://github.com/flx42/layer-dedup-test/blob/master/pull.sh)

* Assemble a large list of image tags in [`tags.list`](https://github.com/flx42/layer-dedup-test/blob/master/tags.list) by querying each DockerHub repository listed in [`repos.list`](https://github.com/flx42/layer-dedup-test/blob/master/tags.list).
* Download all image tags in parallel using [GNU Parallel](https://www.gnu.org/software/parallel/).
* **This script might be heavy on the Docker Hub infrastructure, be nice.**

```
+ du -sh /mnt/docker/overlay2
822G    /mnt/docker/overlay2
```

## [`rmlint-hardlink.sh`](https://github.com/flx42/layer-dedup-test/blob/master/rmlint-hardlink.sh)

* File-level deduplication test.
* Uses [rmlint](https://rmlint.readthedocs.io/en/latest/) with hardlinks to eliminate duplicate files.

```
+ rmlint --threads=64 -v -T df --config=sh:handler=hardlink /mnt/docker/overlay2
+ ./rmlint.sh -d
+ sync
+ du -sh /mnt/docker/overlay2
301G	/mnt/docker/overlay2
```

## [`restic.sh`](https://github.com/flx42/layer-dedup-test/blob/master/restic.sh)

* Block-level deduplication test.
* Uses [restic](https://restic.net/), which does [Content Defined Chunking](https://restic.net/blog/2015-09-12/restic-foundation1-cdc).

```
+ restic backup /mnt/docker/overlay2
scan [/mnt/docker/overlay2]
[4:47] 3254412 directories, 26534922 files, 828.901 GiB
scanned 3254412 directories, 26534922 files in 4:47
[37:53] 100.00%  828.901 GiB / 828.901 GiB  29789334 / 29789334 items  0 errors  ETA 0:00 

duration: 37:53
snapshot 4c536e09 saved
+ du -sh /tmp/restic
244G    /tmp/restic
```
