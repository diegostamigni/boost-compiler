cd boost
cp ./tools/build/src/user-config.jam ./tools/build/src/user-config.jam_iosx
cp ../config/user-config-android.jam ./tools/build/src/user-config.jam
./bjam --without-python --without-serialization link=static runtime-link=static target-os=linux --stagedir=../android-build toolset=gcc-android
cd ../
cd android-build/lib
$NDK_ROOT/toolchains/arm-linux-androideabi-4.8/prebuilt/darwin-x86/bin/arm-linux-androideabi-ar crus libboost.a *.a
cd ../../

