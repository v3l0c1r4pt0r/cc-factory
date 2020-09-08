FROM ubuntu:12.04

RUN apt-get update && apt-get upgrade -yq && apt-get install -yq \
	# for admin access of normal user
	sudo \
	# for ct-ng
	gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
	python3-dev autoconf automake libtool gawk wget bzip2 xz-utils unzip \
	patch libstdc++6 rsync

RUN cd /root && \
	wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.22.0.tar.xz && \
	tar -xvf crosstool-ng-1.22.0.tar.xz && \
	cd crosstool-ng && \
	./configure && \
	make && \
	make install

RUN adduser --disabled-password --gecos '' admin

RUN echo "admin ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/admin && chmod 0440 /etc/sudoers.d/admin

USER admin:admin

RUN mkdir /home/admin/workspace

WORKDIR /home/admin/workspace
