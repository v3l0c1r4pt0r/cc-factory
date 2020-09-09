IMAGE=mipsel-gcc-uclibc
IMAGE_VERSION=4.6.3-1.0.26

all:
	echo "Do sth else. Plz"

build:
	docker rmi -f $(IMAGE):$(IMAGE_VERSION)
	docker build --tag $(IMAGE):$(IMAGE_VERSION) .

run:
	docker run --detach --name "cross-gcc" --tty $(IMAGE):$(IMAGE_VERSION)

shell:
	docker exec --interactive --tty cross-gcc /bin/bash

stop:
	docker stop cross-gcc

rm:
	docker rm -f cross-gcc
