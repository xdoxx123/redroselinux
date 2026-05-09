#!/bin/sh
set -e
version=0.1.0

rm -rf package
cargo build --release
mkdir -p package
mkdir -p package/usr
mkdir -p package/usr/bin
cp target/release/mkfstab package/usr/bin/
echo "version $version" > package/car
fakeroot tar -I zstd -cf mkfstab.tar.zst package/
