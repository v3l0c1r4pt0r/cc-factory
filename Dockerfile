ARG JOBS=1
FROM ubuntu:12.04

# prepare system and prerequisites
RUN apt-get update && apt-get upgrade -yq && apt-get install -yq \
	# for admin access of normal user
	sudo \
  # for toolchain cross-compilation
  gcc g++ make gawk texinfo file m4 patch \
	# for pulling sources
	wget ca-certificates

# add unprivileged user and set up workspace
RUN adduser --disabled-password --gecos '' admin

RUN echo "admin ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/admin && chmod 0440 /etc/sudoers.d/admin

USER admin:admin

RUN mkdir /home/admin/workspace

WORKDIR /home/admin/workspace

# setup component versions
ENV ARCH mips
ENV TARGET mipsel-unknown-linux-gnu
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

# Step 1. Build binutils
RUN tput -Txterm setaf 2; echo "[1/10] Building binutils..."; tput -Txterm setaf 7;
RUN mkdir build-binutils && \
	mkdir -p install-binutils && \
  cd build-binutils && \
  ../binutils-${BINUTILS_VER}/configure --prefix=`pwd`/../install-binutils --target=${TARGET} --disable-multilib && \
  make -j${JOBS} && \
  sudo make install

# Step 2. Prepare kernel headers
RUN tput -Txterm setaf 2; echo "[2/10] Installing kernel headers..."; tput -Txterm setaf 7;
RUN cd linux-${LINUX_VER} && \
	sudo make ARCH=${ARCH} INSTALL_HDR_PATH=/usr/${TARGET} headers_install

# Step 3. Build GMP
RUN tput -Txterm setaf 2; echo "[3/10] Building GMP..."; tput -Txterm setaf 7;
RUN mkdir -p build-gmp && \
	mkdir -p install-gmp && \
	cd build-gmp && \
	../gmp-${GMP_VER}/configure --prefix=`pwd`/../install-gmp && \
	make -j${JOBS} && \
	make install

# Step 4. Build MPFR
RUN tput -Txterm setaf 2; echo "[4/10] Building MPFR..."; tput -Txterm setaf 7;
RUN mkdir -p build-mpfr && \
	mkdir -p install-mpfr && \
	cd build-mpfr && \
	../mpfr-${MPFR_VER}/configure --prefix=`pwd`/../install-mpfr --with-gmp=`pwd`/../install-gmp && \
	make -j${JOBS} && \
	make install

# Step 5. Build MPC
RUN tput -Txterm setaf 2; echo "[5/10] Building MPC..."; tput -Txterm setaf 7;
COPY gmp_rnda.patch /home/admin/workspace
RUN mkdir -p build-mpc && \
	mkdir -p install-mpc && \
	cd mpc-${MPC_VER} && \
	patch -p1 <../gmp_rnda.patch && \
	cd - && \
	cd build-mpc && \
	../mpc-${MPC_VER}/configure \
		--prefix=`pwd`/../install-mpc \
		--with-gmp=`pwd`/../install-gmp \
		--with-mpfr=`pwd`/../install-mpfr && \
	make -j${JOBS} && \
	make install

# Step 6. First pass compiler
RUN tput -Txterm setaf 2; echo "[6/10] Building first pass of GCC..."; tput -Txterm setaf 7;
RUN mkdir -p build-gcc && \
	mkdir -p install-1st-gcc && \
  cd build-gcc && \
  ../gcc-${GCC_VER}/configure \
		--prefix=`pwd`/../install-1st-gcc \
		--target=${TARGET} \
		--with-gmp=`pwd`/../install-gmp \
		--with-mpfr=`pwd`/../install-mpfr \
		--with-mpc=`pwd`/../install-mpc \
		--enable-languages=c,c++ \
		--disable-multilib && \
  make -j${JOBS} all-gcc && \
  sudo make install-gcc
