#!/bin/bash

if [[ $NDK_ROOT = *[!\ ]* ]]; then
    echo "Using the Android NDK: $NDK_ROOT"
else
    echo "In order to build Boost for Android, please set the env variable NDK_ROOT"
    exit 1
fi

source bootstrap.sh
mkdir android-build

cd $(pwd)/boost
cp $(pwd)/tools/build/src/user-config.jam $(pwd)/tools/build/src/user-config.jam_iosx
cp $(pwd)/../config/user-config-android.jam $(pwd)/tools/build/src/user-config.jam

if [[ $BOOST_LIBS = *[!\ ]* ]]; then
    BOOST_LIBS_COMMA=$(echo $BOOST_LIBS | sed -e "s/ /,/g")
    echo "Bootstrapping (with libs $BOOST_LIBS_COMMA)"
    ./bootstrap.sh --with-libraries=$BOOST_LIBS_COMMA
else
    echo "Bootstrapping (with all libs)"
    ./bootstrap.sh
fi

#./bjam --without-python --without-serialization link=static runtime-link=static target-os=linux --stagedir=../android-build toolset=gcc-android
./bjam --build-dir=../android-build --stagedir=../android-build/stage --prefix=$PREFIXDIR architecture=arm define=_LITTLE_ENDIAN link=static  toolset=gcc-android stage
#./bjam --build-dir=../android-build --stagedir=../android-build/stage --prefix=$PREFIXDIR architecture=arm define=_LITTLE_ENDIAN link=static toolset=gcc-android install

cd ../
cd android-build/stage/lib
$NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/bin/arm-linux-androideabi-ar crus libboost.a *.a
cd ../../
