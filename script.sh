#!/bin/bash

dpkg --add-architecture i386 && apt-get update && apt-get install -y git ccache automake bc lzop bison gperf build-essential zip curl zlib1g-dev zlib1g-dev:i386 g++-multilib python-networkx libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng &&
git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 /pipeline/build/root/toolchain/aarch64-linux-android-4.9
git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 /pipeline/build/root/toolchain/aarch64-linux-android-clang
KERNEL_DIR=$PWD
ANYKERNEL_DIR=$KERNEL_DIR/AnyKernel2
TOOLCHAINDIR=/pipeline/build/root/toolchain/aarch64-linux-android-4.9
CCACHEDIR=../CCACHE/whyred
DATE=$(date +"%d%m%Y")
KERNEL_NAME="Lasagnatest-Kernel"
DEVICE="-whyred-"
VER="-v0.0.1"
TYPE="-O-MR1"
FINAL_ZIP="$KERNEL_NAME""$DEVICE""$DATE""$TYPE""$VER".zip

rm $ANYKERNEL_DIR/Image.gz-dtb
rm $KERNEL_DIR/arch/arm64/boot/Image.gz $KERNEL_DIR/arch/arm64/boot/Image.gz-dtb

export ARCH=arm64
export CXX="/pipeline/build/root/toolchain/aarch64-linux-android-clang/clang-4679922/bin/clang++"
export CC="/pipeline/build/root/toolchain/aarch64-linux-android-clang/clang-4679922/bin/clang"
export CLANG_TRIPLE=aarch64-linux-gnu-
export KBUILD_BUILD_USER="Andrea"
export KBUILD_BUILD_HOST="SlaveBuilder"
export CROSS_COMPILE=/pipeline/build/root/toolchain/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export LD_LIBRARY_PATH=/pipeline/build/root/toolchain/aarch64-linux-android-4.9/lib/
export USE_CCACHE=1
export CCACHE_DIR=$CCACHEDIR/.ccache
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="New kernel build started for whyred!" -d chat_id=@andreabuilds;
make clean && make mrproper
make whyred_defconfig
make -j$( nproc --all )

{

  #try block

cp $KERNEL_DIR/arch/arm64/boot/Image.gz-dtb $ANYKERNEL_DIR

} || {

  #catch block

  if [ $? != 0 ]; then

    curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build failed :c" -d chat_id=@andreabuilds;
    exit 1
 
  fi

}
cd $ANYKERNEL_DIR
zip -r9 $FINAL_ZIP * -x *.zip $FINAL_ZIP
message="Build completed with the latest commit -"
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="$message $(git log --pretty=format:'%h : %s' -1)" -d chat_id=@andreabuilds
curl -F chat_id="-1001235553927" -F document=@"$FINAL_ZIP" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
curl -F chat_id="-1001235553927" -F document=@"$KERNEL_DIR/include/generated/compile.h" https://api.telegram.org/bot$BOT_API_KEY/sendDocument

mv $FINAL_ZIP /pipeline/output/$FINAL_ZIP
