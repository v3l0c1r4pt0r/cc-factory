IMAGE=mipsel-gcc-uclibc
IMAGE_VERSION=4.6.4-1.0.26

# modify to use more cores for compilation, set to nothing to let make pick value automatically
JOBS=1

all:
	echo "Do sth else. Plz"

build:
	docker rmi -f $(IMAGE):$(IMAGE_VERSION)
	docker build --build-arg JOBS=$(JOBS) --tag $(IMAGE):$(IMAGE_VERSION) .

run: outdir
	docker run --detach --name "cross-gcc" --tty -v $(shell pwd)/outdir:/mnt/outdir $(IMAGE):$(IMAGE_VERSION)

shell:
	docker exec --interactive --tty cross-gcc /bin/bash

stop:
	docker stop cross-gcc

rm:
	docker rm -f cross-gcc

outdir:
	mkdir -p $@

sdk:
	docker exec cross-gcc /home/admin/build-sdk.sh
