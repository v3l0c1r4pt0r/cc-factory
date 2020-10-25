#!/bin/sh
# builds SDK package and exports to host system
# this is meant to run in container only
# Usage:
#   build-sdk.sh IMAGE IMAGE-VERSION
if [ $# -ne 2 ]; then
  echo "Usage: $0 IMAGE IMAGE-VERSION"
	exit 1
fi

IMAGE=$1
IMAGE_VERSION=$2

tar -zcvf /home/admin/workspace/${IMAGE}-${IMAGE_VERSION}.tar.gz ${SDK_ROOT}
sudo cp -pr /home/admin/workspace/${IMAGE}-${IMAGE_VERSION}.tar.gz /mnt/outdir/
