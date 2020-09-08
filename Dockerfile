FROM ubuntu:12.04

RUN apt-get update && apt-get upgrade -yq && apt-get install -yq gcc

RUN cd /root && \
	wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.22.0.tar.xz && \
	tar -xvf crosstool-ng-1.22.0.tar.xz && \
	cd crosstool-ng && \
	./configure && \
	make && \
	make install
