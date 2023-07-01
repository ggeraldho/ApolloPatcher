#/bin/sh

export PREFIX=$THEOS/toolchain/Xcode11.xctoolchain/usr/bin/
make clean
make package

export -n PREFIX
make clean
make package install THEOS_PACKAGE_SCHEME=rootless
