ARG JOBS=1
FROM ubuntu:12.04

# prepare system and prerequisites
RUN apt-get update && apt-get upgrade -yq && apt-get install -yq \
  # for admin access of normal user
  sudo \
  # for toolchain cross-compilation
  binutils libc6 libc6-dev libgcc1 make gawk texinfo file m4 patch \
  # for pulling sources
  wget ca-certificates

RUN mkdir dpkg && cd dpkg && \
  wget http://old-releases.ubuntu.com/ubuntu/pool/universe/g/gcc-3.3/cpp-3.3_3.3.6-15ubuntu4_amd64.deb && \
  wget http://old-releases.ubuntu.com/ubuntu/pool/universe/g/gcc-3.3/gcc-3.3-base_3.3.6-15ubuntu4_amd64.deb && \
  wget http://old-releases.ubuntu.com/ubuntu/pool/universe/g/gcc-3.3/gcc-3.3_3.3.6-15ubuntu4_amd64.deb && \
  dpkg -i gcc-3.3-base_3.3.6-15ubuntu4_amd64.deb && \
  dpkg -i cpp-3.3_3.3.6-15ubuntu4_amd64.deb && \
  dpkg -i gcc-3.3_3.3.6-15ubuntu4_amd64.deb

RUN ln -s `which gcc-3.3` /bin/gcc && \
  ln -s `which g++-3.3` /bin/g++ && \
  ln -s `which ar-3.3` /bin/ar && \
  ln -s `which ranlib-3.3` /bin/ranlib

# add unprivileged user and set up workspace
RUN adduser --disabled-password --gecos '' admin

RUN echo "admin ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/admin && chmod 0440 /etc/sudoers.d/admin

USER admin:admin

RUN mkdir /home/admin/workspace

WORKDIR /home/admin/workspace

# target platform
ENV ARCH mips
ENV TARGET mips-linux-uclibc
ENV SDK_ROOT /opt/${TARGET}

# setup component versions
ENV BINUTILS_VER 2.23.2
ENV GCC_VER 3.3.2
ENV LINUX_BRANCH v4.x
ENV LINUX_VER 4.1.38
ENV LIBC "uClibc-ng"
#ENV LIBC "glibc"
ENV LIBC_VER 1.0.12
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
RUN bash -c "if [ \"z${LIBC}\" == \"zglibc\" ]; then wget http://ftpmirror.gnu.org/glibc/glibc-${LIBC_VER}.tar.xz; fi"
RUN bash -c "if [ \"z${LIBC}\" == \"zuClibc-ng\" ]; then wget https://downloads.uclibc-ng.org/releases/${LIBC_VER}/uClibc-ng-${LIBC_VER}.tar.gz; fi"
RUN wget http://ftpmirror.gnu.org/gmp/gmp-${GMP_VER}.tar.gz
RUN wget http://ftpmirror.gnu.org/mpfr/mpfr-${MPFR_VER}.tar.gz
RUN wget http://www.multiprecision.org/downloads/mpc-${MPC_VER}.tar.gz
RUN if [ "z${ISL_VER}" != "z" ]; then echo "ISL is not supported yet!"; exit 1; fi
RUN if [ "z${CLOOG_VER}" != "z" ]; then echo "CLooG is not supported yet!"; exit 1; fi

# extract sources
RUN tput -Txterm setaf 6; echo "Extracting sources..."; tput -Txterm setaf 7;
RUN for f in *.tar*; do echo "$f...";tar -xf $f; echo "done"; done

# prepare installation directory
RUN tput -Txterm setaf 6; echo "Preparing installation directory..."; tput -Txterm setaf 7;
RUN sudo mkdir -p ${SDK_ROOT} && sudo chown admin:admin ${SDK_ROOT}

# Step 1. Build binutils
RUN tput -Txterm setaf 2; echo "[1/10] Building binutils..."; tput -Txterm setaf 7;
RUN mkdir build-binutils && \
  cd build-binutils && \
  ../binutils-${BINUTILS_VER}/configure --prefix=${SDK_ROOT} --target=${TARGET} --disable-multilib && \
  make -j${JOBS} && \
  make install

# Step 2. Prepare kernel headers
RUN tput -Txterm setaf 2; echo "[2/10] Installing kernel headers..."; tput -Txterm setaf 7;
RUN cd linux-${LINUX_VER} && \
  make ARCH=${ARCH} INSTALL_HDR_PATH=${SDK_ROOT}/${TARGET} headers_install

# Step 3. Build GMP
RUN tput -Txterm setaf 2; echo "[3/10] Building GMP..."; tput -Txterm setaf 7;
RUN mkdir -p build-gmp && \
  cd build-gmp && \
  ../gmp-${GMP_VER}/configure --prefix=${SDK_ROOT} && \
  make -j${JOBS} && \
  make install

# Step 4. Build MPFR
RUN tput -Txterm setaf 2; echo "[4/10] Building MPFR..."; tput -Txterm setaf 7;
RUN mkdir -p build-mpfr && \
  cd build-mpfr && \
  ../mpfr-${MPFR_VER}/configure --prefix=${SDK_ROOT} --with-gmp=${SDK_ROOT} && \
  make -j${JOBS} && \
  make install

# Step 5. Build MPC
RUN tput -Txterm setaf 2; echo "[5/10] Building MPC..."; tput -Txterm setaf 7;
COPY gmp_rnda.patch /home/admin/workspace
RUN mkdir -p build-mpc && \
  cd mpc-${MPC_VER} && \
  patch -p1 <../gmp_rnda.patch && \
  cd - && \
  cd build-mpc && \
  ../mpc-${MPC_VER}/configure \
    --prefix=${SDK_ROOT} \
    --with-gmp=${SDK_ROOT} \
    --with-mpfr=${SDK_ROOT} && \
  make -j${JOBS} && \
  make install

# Step 6. First pass compiler
RUN tput -Txterm setaf 2; echo "[6/10] Building first pass of GCC..."; tput -Txterm setaf 7;
RUN mkdir -p build-gcc && \
  cd build-gcc && \
  ../gcc-${GCC_VER}/configure \
    --prefix=${SDK_ROOT} \
    --target=${TARGET} \
    --with-gmp=${SDK_ROOT} \
    --with-mpfr=${SDK_ROOT} \
    --with-mpc=${SDK_ROOT} \
    --enable-languages=c,c++ \
    --disable-multilib && \
  make all-gcc && \
  #make -j${JOBS} all-gcc && \
  make install-gcc

# Step 7. Library headers
RUN tput -Txterm setaf 2; echo "[7/10] Building LIBC headers and CRT files..."; tput -Txterm setaf 7;
COPY uClibc.config /home/admin/workspace/uClibc-ng-${LIBC_VER}/.config
RUN export ESCAPED_ROOT=`bash -c 'echo ${SDK_ROOT//\//\\\/}'` && \
  sed -i 's/KERNEL_HEADERS=""/KERNEL_HEADERS="'${ESCAPED_ROOT}'\/'${TARGET}'\/include"/g' /home/admin/workspace/uClibc-ng-${LIBC_VER}/.config && \
  sed -i 's/CROSS_COMPILER_PREFIX=""/CROSS_COMPILER_PREFIX="'${TARGET}'-"/g' /home/admin/workspace/uClibc-ng-${LIBC_VER}/.config && \
  sed -i 's/RUNTIME_PREFIX=.*/RUNTIME_PREFIX="'${ESCAPED_ROOT}'\/'${TARGET}'\/"/g' /home/admin/workspace/uClibc-ng-${LIBC_VER}/.config && \
  sed -i 's/DEVEL_PREFIX=.*/DEVEL_PREFIX="'${ESCAPED_ROOT}'\/'${TARGET}'\/"/g' /home/admin/workspace/uClibc-ng-${LIBC_VER}/.config && \
  sed -i 's/CROSS_COMPILER_PREFIX=""/CROSS_COMPILER_PREFIX="'${TARGET}'-"/g' /home/admin/workspace/uClibc-ng-${LIBC_VER}/.config
ENV PATH="${SDK_ROOT}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${SDK_ROOT}/lib"
RUN cd uClibc-ng-${LIBC_VER} && \
  make pregen startfiles CROSS_COMPILE=$TARGET- && \
  make install_headers install_startfiles CROSS_COMPILE=$TARGET- && \
  ${TARGET}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${SDK_ROOT}/${TARGET}/lib/libc.so
# glibc:
#RUN mkdir -p build-libc && \
#  mkdir -p install-libc && \
#  cd build-libc && \
#  ../${LIBC}-${LIBC_VER}/configure \
#    --prefix=`pwd`/../install-libc \
#    --target=${TARGET} && \
#  make all-gcc && \
#  #make -j${JOBS} all-gcc && \
#  sudo make install-gcc

RUN tput -Txterm setaf 2; echo "[8/10] Building support library..."; tput -Txterm setaf 7;
RUN cd build-gcc && \
  make all-target-libgcc && \
  make install-target-libgcc

RUN tput -Txterm setaf 2; echo "[9/10] Building C library..."; tput -Txterm setaf 7;
RUN cd uClibc-ng-${LIBC_VER} && \
  make CROSS_COMPILE=$TARGET- && \
  make install CROSS_COMPILE=$TARGET-

RUN tput -Txterm setaf 2; echo "[10/10] Building final GCC..."; tput -Txterm setaf 7;
RUN cd build-gcc && \
  sed -i '/using ::tmpnam;/d' /home/admin/workspace/gcc-4.6.4/libstdc++-v3/include/c_global/cstdio && \
  make && \
  make install

RUN tput -Txterm setaf 6; echo "Compressing and exporting SDK..."; tput -Txterm setaf 7;
RUN sudo mkdir /mnt/outdir && sudo chown admin:admin /mnt/outdir
VOLUME /mnt/outdir
RUN tar -zcvf /home/admin/workspace/${TARGET}.tar.gz ${SDK_ROOT}
RUN sudo cp -pr /home/admin/workspace/${TARGET}.tar.gz /mnt/outdir/
