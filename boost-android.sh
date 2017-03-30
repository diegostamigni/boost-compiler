#!/bin/bash
BOOST_VERSION="1.60.0"
BOOST_SRC="$(pwd)/boost"

OUTPUTDIR="$(pwd)/android"
BUILDDIR="$(pwd)/android-build"
STAGEDIR="${BUILDDIR}/stage"
PREFIXDIR="${STAGEDIR}/prefix"

if [ -z "$1" ]; then
	echo "BOOST_VERSION has not been specified, will use $BOOST_VERSION as default"
else
	BOOST_VERSION="$1"
	echo "Using BOOST_VERSION: $BOOST_VERSION"
fi

if [[ $ANDROID_NDK_ROOT = *[!\ ]* ]]; then
    echo "Using the Android NDK: $ANDROID_NDK_ROOT"
else
    echo "In order to build Boost for Android, please set the env variable ANDROID_NDK_ROOT"
    exit 1
fi

rm -rf ${OUTPUTDIR}
rm -rf ${BUILDDIR}
rm -rf ${STAGEDIR}
rm -rf ${PREFIXDIR}

source bootstrap.sh

if [ -d $BOOST_SRC ]
then
    cd $BOOST_SRC
    git reset --hard
    git checkout master
    git fetch --all
    git pull origin master
    git branch -D boost-$BOOST_VERSION
    git clean -d -f
else
    git clone --recursive https://github.com/boostorg/boost.git $BOOST_SRC
    cd $BOOST_SRC
fi

git checkout tags/boost-$BOOST_VERSION -b boost-$BOOST_VERSION
git submodule sync
git submodule update

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

./bjam --build-dir="${BUILDDIR}" --stagedir="${STAGEDIR}" --prefix="${PREFIXDIR}" architecture=arm define=_LITTLE_ENDIAN link=static  toolset=gcc-android stage
./bjam --build-dir="${BUILDDIR}" --stagedir="${STAGEDIR}" --prefix="${PREFIXDIR}" architecture=arm define=_LITTLE_ENDIAN link=static  toolset=gcc-android install

cd "${STAGEDIR}"/lib
$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/bin/arm-linux-androideabi-ar crus libboost.a *.a

mkdir "${OUTPUTDIR}"
cd "${OUTPUTDIR}"

rsync -avp "${PREFIXDIR}"/include .

mkdir armeabi
cp "${STAGEDIR}"/lib/libboost.a armeabi/
