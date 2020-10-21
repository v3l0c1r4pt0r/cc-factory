# CC-Factory

Factory for cross compilers inside of Docker container

## Overview

This repository provides Docker containers that allows to build very specific
GCC-LINUX-LIBC toolchain in reproducible manner. You don't see anything here,
because it is organised into branches. Each branch is separate triplet of
compiler, OS and standard library, usually with very specific version of each
component.

Main purpose from developing this repository is to allow to recreate toolchains
for systems that did not provide public SDKs. By the way it should also work
decently in providing latest compilers for any architecture one would like.

## Usage

1. Select desired target from [Table of contents](#table-of-contents)
2. Checkout to target's branch: `git checkout <branch-name>`
3. Make sure Docker is running and you have access to Docker daemon
4. Build container with `make build`
5. Wait couple of minutes for toolchain to build
6. Run container: `make run`
7. If you want to play with toolchain in isolated container, type `make shell`.
   You will be dropped into normal user interactive shell
8. If you prefer to run toolchain on your own system, type: `make sdk`
9. `outdir` directory should appear, with tarball inside

## Installing SDK

If you decided to export SDK outside container, its installation is as simple as
unpacking the package to `/`:

```sh
tar -zxvf mips-linux-uclibc.tar.gz -C /
```

By default SDK is installed in `/opt/${TARGET}` directory, where `${TARGET}` is
full target name, e.g. `mips-linux-uclibc` for big endian MIPS with uClibc as C
library.

If you prefer to have SDK installed elsewhere, you have to specify this before
attempting to build the image, by editing `SDK_ROOT` variable in `Dockefile`. If
you try to unpack SDK into different path, it simply won't work, as this path is
hardcoded into compiler!

## Table of contents

Platform | CC        | OS            | LIBC          | branch
---------|-----------|---------------|---------------|-------------------------------------------
MIPS     | gcc 4.6.4 | Linux 4.1.38  | uClibc 1.0.12 | `mips-gcc4.6-linux4.1.38-uclibc1.0.12`
MIPSEL   | gcc 4.6.4 | Linux 3.4.113 | uClibc 1.0.26 | `mipsel-gcc4.6-linux3.4.113-uclibc1.0.26`
