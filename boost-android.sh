#!/bin/bash
# Diego Stamigni

BOOST_VERSION="1.60.0"

BOOST_SRC="$(pwd)/boost"
CONFIGDIR="$(pwd)/config"
SCRIPTSDIR="$(pwd)/scripts"
OUTPUTDIR="$(pwd)/android"
BUILDDIR="$(pwd)/android-build"

TOOLSET=gcc-android
STAGEDIR="${BUILDDIR}/stage"
PREFIXDIR="${STAGEDIR}/prefix"
ABI="armeabi"

if [ -z "$1" ]; then
	echo "BOOST_VERSION has not been specified, will use $BOOST_VERSION as default"
else
	BOOST_VERSION="$1"
	echo "Using BOOST_VERSION: $BOOST_VERSION"
fi

if [ -z "$2" ]; then
    echo "ABI not specified, will use $ABI as default"
else
    ABI="$2"
    echo "Using ABI: $ABI"
fi

if [[ $ANDROID_NDK_ROOT = *[!\ ]* ]]; then
    echo "Using the Android NDK: $ANDROID_NDK_ROOT"
else
    echo "In order to build Boost for Android, please set the env variable ANDROID_NDK_ROOT"
    exit 1
fi

HELPER="${SCRIPTSDIR}/${ABI}".sh
source "${HELPER}"

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

cp "${CONFIGDIR}/${ABI}".jam $(pwd)/tools/build/src/user-config.jam
cp "${CONFIGDIR}/${ABI}".jam $(pwd)/project-config.jam

if [[ $BOOST_LIBS = *[!\ ]* ]]; then
    BOOST_LIBS_COMMA=$(echo $BOOST_LIBS | sed -e "s/ /,/g")
    echo "Bootstrapping (with libs $BOOST_LIBS_COMMA)"
    ./bootstrap.sh --with-libraries=$BOOST_LIBS_COMMA
else
    echo "Bootstrapping (with all libs)"
    ./bootstrap.sh
fi

./bjam -q \
    -j8 \
    --build-dir="${BUILDDIR}" \
    --stagedir="${STAGEDIR}" \
    --prefix="${PREFIXDIR}" \
    --layout=system \
    architecture=${ARCH} \
    define=_LITTLE_ENDIAN \
    threading=multi \
    link=static \
    target-os=linux \
    toolset=${TOOLSET} \
    install

# cd "${STAGEDIR}"/prefix/lib
# ${AR} crus libboost.a *.a

mkdir -p "${OUTPUTDIR}"/lib/"${ABI}"
rsync -avp "${PREFIXDIR}"/include "${OUTPUTDIR}"
rsync -avp "${STAGEDIR}"/prefix/lib/* "${OUTPUTDIR}"/lib/"${ABI}"/
# cp "${STAGEDIR}"/prefix/lib/libboost.a lib/"${ABI}"/libboost.a
