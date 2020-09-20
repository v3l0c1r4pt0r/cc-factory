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

## Table of contents

Platform | CC        | OS            | LIBC          | branch
---------|-----------|---------------|---------------|-------------------------------------------
MIPS     | gcc 4.6.4 | Linux 4.1.38  | uClibc 1.0.12 | `mips-gcc4.6-linux4.1.38-uclibc1.0.12`
MIPSEL   | gcc 4.6.4 | Linux 3.4.113 | uClibc 1.0.26 | `mipsel-gcc4.6-linux3.4.113-uclibc1.0.26`
