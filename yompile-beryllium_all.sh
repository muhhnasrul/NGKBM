#!/bin/sh

# Many parts of this script were taken from @REIGNZ, @idkwhoiam322 and @raphielscape . Huge thanks to them.

# Some general variables
PHONE="beryllium"
ARCH="arm64"
SUBARCH="arm64"
DEFCONFIG=nogravity_defconfig
#DEFCONFIG=beryllium_defconfig
COMPILER=clang
LINKER=""

# Outputs
rm -rf out
rm -rf NGKBM/

mkdir out

mkdir NGKBM/
mkdir NGKBM/SE-old
mkdir NGKBM/NSE-old
mkdir NGKBM/SE-new
mkdir NGKBM/NSE-new

# Export shits
export KBUILD_BUILD_USER=DioP
export KBUILD_BUILD_HOST=Ncessvie

# Speed up build process
MAKE="./makeparallel"

# Basic build function
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

Build () {
make -j$(nproc --all) O=out LLVM=1 LLVM_IAS=1 \
ARCH=${ARCH} \
CC=${COMPILER} \
CROSS_COMPILE=${COMPILERDIR}/bin/aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=${COMPILERDIR}/bin/arm-linux-gnueabi- \
LD_LIBRARY_PATH=${COMPILERDIR}/lib
}

Build_lld () {
make -j$(nproc --all) O=out LLVM=1 LLVM_IAS=1 \
ARCH=${ARCH} \
CC=${COMPILER} \
CROSS_COMPILE=${COMPILERDIR}/bin/aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=${COMPILERDIR}/bin/arm-linux-gnueabi- \
LD=ld.lld \
AR=llvm-ar \
NM=llvm-nm \
OBJCOPY=llvm-objcopy \
OBJDUMP=llvm-objdump \
STRIP=llvm-strip \
ld-name=${LINKER} 
}

# Make defconfig

make O=out ARCH=${ARCH} ${DEFCONFIG}
if [ $? -ne 0 ]
then
    echo "Build failed"
else
    echo "Made ${DEFCONFIG}"
fi

# Build starts here
if [ -z ${LINKER} ]
then
    #Start with SE-old
    cp firmware/touch_fw_variant/9.1.24/* firmware/
    cp arch/arm64/boot/dts/qcom/SE_NSE/SE/* arch/arm64/boot/dts/qcom/
    Build
else
    Build_lld
fi

if [ $? -ne 0 ]
then
    echo "Build failed"
    rm -rf out/outputs/${PHONE}/*
else
    echo "Build succesful"
    cp out/arch/arm64/boot/Image.gz-dtb NGKBM/SE-old/Image.gz-dtb
    
    #NSE-old
    cp arch/arm64/boot/dts/qcom/SE_NSE/NSE/* arch/arm64/boot/dts/qcom/
    Build
    if [ $? -ne 0 ]
    then
        echo "Build failed"
        rm -rf out/outputs/${PHONE}/NSE-old/*
    else
        echo "Build succesful"
        cp out/arch/arm64/boot/Image.gz-dtb NGKBM/NSE-old/Image.gz-dtb

        #SE-new
        cp firmware/touch_fw_variant/10.3.7/* firmware/
        cp arch/arm64/boot/dts/qcom/SE_NSE/SE/* arch/arm64/boot/dts/qcom/
        Build
        if [ $? -ne 0 ]
        then
            echo "Build failed"
            rm -rf out/outputs/${PHONE}/SE-new/*
        else
            echo "Build succesful"
            cp out/arch/arm64/boot/Image.gz-dtb NGKBM/SE-new/Image.gz-dtb

            #NSE-new
            cp arch/arm64/boot/dts/qcom/SE_NSE/NSE/* arch/arm64/boot/dts/qcom/
            Build
            if [ $? -ne 0 ]
            then
                echo "Build failed"
                rm -rf out/outputs/${PHONE}/NSE-new/*
            else
                echo "Build succesful"
                cp out/arch/arm64/boot/Image.gz-dtb NGKBM/NSE-new/Image.gz-dtb
                
            fi
        fi
    fi
fi

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
 2>&1 | tee -a out/compile.log