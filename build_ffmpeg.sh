#!/bin/sh

arch=x86_64
archdir=x64
clean_build=true
cross_prefix=x86_64-w64-mingw32-

make_dirs() (
  mkdir -p bin_${archdir}/lib
  mkdir -p bin_${archdir}d/lib
)

copy_libs() (
  # install -s --strip-program=${cross_prefix}strip lib*/*-lav-*.dll ../bin_${archdir}
  cp lib*/*-lav-*.dll ../bin_${archdir}
  ${cross_prefix}strip ../bin_${archdir}/*-lav-*.dll
  cp -u lib*/*.lib ../bin_${archdir}/lib

  cp lib*/*-lav-*.dll ../bin_${archdir}d
  ${cross_prefix}strip ../bin_${archdir}d/*-lav-*.dll
  cp -u lib*/*.lib ../bin_${archdir}d/lib
)

clean() (
  make distclean > /dev/null 2>&1
)

configure() (
  OPTIONS="
    --enable-shared                 \
    --disable-static                \
    --enable-gpl                    \
    --enable-version3               \
    --enable-w32threads             \
    --disable-demuxer=matroska      \
    --disable-filters               \
    --enable-filter=scale,yadif,w3fdif \
    --disable-protocol=async,cache,concat,httpproxy,icecast,md5,subfile \
    --disable-muxers                \
    --enable-muxer=spdif            \
    --disable-bsfs                  \
    --enable-bsf=extract_extradata,vp9_superframe_split \
    --disable-cuda                  \
    --disable-cuvid                 \
    --disable-nvenc                 \
    --enable-libdav1d               \
    --enable-libspeex               \
    --enable-libopencore-amrnb      \
    --enable-libopencore-amrwb      \
    --enable-avresample             \
    --enable-avisynth               \
    --disable-avdevice              \
    --disable-postproc              \
    --disable-swresample            \
    --disable-encoders              \
    --disable-devices               \
    --disable-programs              \
    --disable-debug                 \
    --disable-doc                   \
    --disable-schannel              \
    --enable-gnutls                 \
    --enable-gmp                    \
    --build-suffix=-lav             \
    --arch=${arch}"

  EXTRA_CFLAGS="-march=native -D_WIN32_WINNT=0x0A00 -DWINVER=0x0A00"
  EXTRA_LDFLAGS=""
  PKG_CONFIG_PREFIX_DIR=""
  export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:../thirdparty/64/lib/pkgconfig/"
    OPTIONS="${OPTIONS} --enable-cross-compile --cross-prefix=${cross_prefix} --target-os=mingw32 --pkg-config=pkg-config"
    EXTRA_CFLAGS="${EXTRA_CFLAGS} -I../thirdparty/64/include"
    EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -L../thirdparty/64/lib"
    PKG_CONFIG_PREFIX_DIR="--define-variable=prefix=../thirdparty/64"

  sh configure --extra-ldflags="${EXTRA_LDFLAGS}" --extra-cflags="${EXTRA_CFLAGS}" --pkg-config-flags="--static ${PKG_CONFIG_PREFIX_DIR}" ${OPTIONS}
)

build() (
  make -j$NUMBER_OF_PROCESSORS
)

make_dirs

echo
echo Building ffmpeg in GCC ${arch} Release config...
echo

cd ffmpeg

if $clean_build ; then
    clean

    ## run configure, redirect to file because of a msys bug
    configure > ffbuild/config.out 2>&1
    CONFIGRETVAL=$?

    ## show configure output
    cat ffbuild/config.out
fi

## Only if configure succeeded, actually build
if ! $clean_build || [ ${CONFIGRETVAL} -eq 0 ]; then
  build &&
  copy_libs
fi

cd ..
