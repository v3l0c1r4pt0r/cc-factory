TAG=$(shell git describe --always --dirty)
TAG?=undefined

# magic for substituting space to minus sign
empty :=
space := $(empty) $(empty)

# split tag on minus sign using spaces to a list
TAGPARTS=$(subst -, ,$(TAG))
# return fields 1-4 of a list and join with minus signs again
IMAGE=$(subst $(space),-,$(wordlist 1,4,$(TAGPARTS)))
# return fields 5-999 (cannot use infinity) of a list and join with minus signs again
IMAGE_VERSION=$(subst $(space),-,$(wordlist 5,999,$(TAGPARTS)))

# default in case something went wrong
ifeq ($(IMAGE),)
IMAGE=cc-factory
endif

ifeq ($(IMAGE_VERSION),)
IMAGE_VERSION=0
endif

# modify to use more cores for compilation, set to nothing to let make pick value automatically
JOBS?=1

all:
	echo "Do sth else. Plz"

build:
	docker rmi -f $(IMAGE):$(IMAGE_VERSION)
	docker build --build-arg=JOBS=$(JOBS) --tag $(IMAGE):$(IMAGE_VERSION) .

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
	docker exec cross-gcc /home/admin/build-sdk.sh $(IMAGE) $(IMAGE_VERSION)

env:
	@echo "IMAGE=$(IMAGE)"
	@echo "IMAGE_VERSION=$(IMAGE_VERSION)"
