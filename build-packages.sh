#!/usr/bin/env bash
set -e

SDK_URL="http://downloads.overthebox.ovh/develop/x86/64/OpenWrt-SDK-x86-64_gcc-4.8-linaro_glibc-2.21.Linux-x86_64.tar.bz2"

if [ ! -d sdk ]; then
    mkdir sdk
    curl ${SDK_URL} | tar jx -C sdk --strip-components 1
fi

mkdir -p sdk/package/overthebox
rsync -a ./ sdk/package/overthebox/ --exclude=sdk --exclude=.git

rm -fr sdk/bin/*

make -C sdk defconfig
make -C sdk world V=s
