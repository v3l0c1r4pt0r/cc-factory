#!/bin/sh
# builds SDK package and exports to host system
# this is meant to run in container only
tar -zcvf /home/admin/workspace/${TARGET}.tar.gz ${SDK_ROOT}
sudo cp -pr /home/admin/workspace/${TARGET}.tar.gz /mnt/outdir/
