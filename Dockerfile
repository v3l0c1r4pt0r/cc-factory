FROM ubuntu:12.04

# prepare system and prerequisites
RUN apt-get update && apt-get upgrade -yq && apt-get install -yq \
	# for admin access of normal user
	sudo \
  # for toolchain cross-compilation
  gcc g++ make gawk \
	# for pulling sources
	wget ca-certificates

# add unprivileged user and set up workspace
RUN adduser --disabled-password --gecos '' admin

RUN echo "admin ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/admin && chmod 0440 /etc/sudoers.d/admin

USER admin:admin

RUN mkdir /home/admin/workspace

WORKDIR /home/admin/workspace

# setup component versions
ENV BINUTILS_VER 2.23.2
ENV GCC_VER 4.6.4
ENV LINUX_BRANCH v3.x
ENV LINUX_VER 3.4.113
ENV LIBC "uClibc-ng"
#ENV LIBC "glibc"
ENV LIBC_VER 1.0.26
ENV GMP_VER 4.3.0
ENV MPFR_VER 3.1.0
ENV MPC_VER 0.8.1
ENV ISL_VER ""
ENV CLOOG_VER ""

# pull sources
RUN tput -Txterm setaf 6; echo "Downloading sources..."; tput -Txterm setaf 7;
RUN wget http://ftpmirror.gnu.org/binutils/binutils-${BINUTILS_VER}.tar.gz
RUN wget http://ftpmirror.gnu.org/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.gz
RUN wget https://www.kernel.org/pub/linux/kernel/${LINUX_BRANCH}/linux-${LINUX_VER}.tar.xz
RUN if [ "${LIBC}" == "glibc" ]; then wget http://ftpmirror.gnu.org/glibc/glibc-${LIBC_VER}.tar.xz; fi
RUN if [ "${LIBC}" == "uClibc-ng" ]; then https://downloads.uclibc-ng.org/releases/${LIBC_VER}/uClibc-ng-${LIBC_VER}.tar.gz; fi
RUN wget http://ftpmirror.gnu.org/gmp/gmp-${GMP_VER}.tar.gz
RUN wget http://ftpmirror.gnu.org/mpfr/mpfr-${MPFR_VER}.tar.gz
RUN wget http://www.multiprecision.org/downloads/mpc-${MPC_VER}.tar.gz
RUN if [ "z${ISL_VER}" != "z" ]; then echo "ISL is not supported yet!"; exit 1; fi
RUN if [ "z${CLOOG_VER}" != "z" ]; then echo "CLooG is not supported yet!"; exit 1; fi

# extract sources
RUN tput -Txterm setaf 6; echo "Extracting sources..."; tput -Txterm setaf 7;
RUN for f in *.tar*; do echo "$f...";tar -xf $f; echo "done"; done
