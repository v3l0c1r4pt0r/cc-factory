FROM ubuntu:12.04

# prepare system and prerequisites
RUN apt-get update && apt-get upgrade -yq && apt-get install -yq \
	# for admin access of normal user
	sudo \
	# for ct-ng
	gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
	python3-dev autoconf automake libtool gawk wget bzip2 xz-utils unzip \
	patch libstdc++6 rsync \
	# for ct-ng pulling via wget
	ca-certificates

# add unprivileged user and set up workspace
RUN adduser --disabled-password --gecos '' admin

RUN echo "admin ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/admin && chmod 0440 /etc/sudoers.d/admin

USER admin:admin

RUN mkdir /home/admin/workspace

RUN mkdir /home/admin/x-tools

# build and install crosstool-ng
WORKDIR /home/admin/workspace

RUN wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.22.0.tar.xz && \
	tar -xvf crosstool-ng-1.22.0.tar.xz && \
	cd crosstool-ng && \
	./configure && \
	sed -i 's/http:\/\/www.multiprecision.org\/mpc\/download/http:\/\/www.multiprecision.org\/downloads/g' \
		./scripts/build/companion_libs/140-mpc.sh && \
	make && \
	sudo make install

WORKDIR /home/admin/x-tools

# install crostool-ng configuration
COPY ./ct-ng.config /home/admin/x-tools/.config

RUN ct-ng oldconfig

WORKDIR /home/admin/workspace
