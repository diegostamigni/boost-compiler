#!/bin/bash

source bootstrap.sh
mkdir android-build

cd boost
cp ./tools/build/src/user-config.jam ./tools/build/src/user-config.jam_iosx
cp ../config/user-config-android.jam ./tools/build/src/user-config.jam

BOOST_LIBS_COMMA=$(echo $BOOST_LIBS | sed -e "s/ /,/g")
echo "Bootstrapping (with libs $BOOST_LIBS_COMMA)"

./bootstrap.sh --with-libraries=$BOOST_LIBS_COMMA
#./bjam --without-python --without-serialization link=static runtime-link=static target-os=linux --stagedir=../android-build toolset=gcc-android
./bjam -j16 --build-dir=../android-build --stagedir=../android-build/stage --prefix=$PREFIXDIR architecture=arm define=_LITTLE_ENDIAN link=static  toolset=gcc-android stage
./bjam -j16 --build-dir=../android-build --stagedir=../android-build/stage --prefix=$PREFIXDIR architecture=arm define=_LITTLE_ENDIAN link=static toolset=gcc-android install

cd ../
cd android-build/stage/lib
$NDK_ROOT/toolchains/arm-linux-androideabi-4.8/prebuilt/darwin-x86/bin/arm-linux-androideabi-ar crus libboost.a *.a
cd ../../

