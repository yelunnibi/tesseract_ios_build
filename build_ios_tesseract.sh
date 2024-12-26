#!/bin/bash

# Tesseract and dependency versions
TESSERACT_VERSION="5.3.3"
LEPTONICA_VERSION="1.85.0"
PNG_VERSION="1.6.40"
ZLIB_VERSION="1.3.1"
ICU_VERSION="73.2"

# iOS compilation configuration
DEVELOPER_ROOT="/Applications/Xcode.app/Contents/Developer"
IOS_SDK="${DEVELOPER_ROOT}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
DEPLOYMENT_TARGET="15.0"

# Output directory (use absolute path)
HEAD_PATH="$(pwd)/ios-libraries/leptonica-ios"
LEP_PATH="$(pwd)/ios-libraries/leptonica-ios"
PNG_PATH="$(pwd)/ios-libraries/libpng-ios"
JPEG_PATH="$(pwd)/ios-libraries/libjpeg-ios"
TIFF_PATH="$(pwd)/ios-libraries/libtiff-ios"
WEBP_PATH="$(pwd)/ios-libraries/libwebp-ios"
OPENJPEG_PATH="$(pwd)/ios-libraries/libopenjpeg-ios"


OUTPUT_DIR="$(pwd)/ios-libraries/tesseract-ios"
mkdir -p "$OUTPUT_DIR"

# Download URLs
TESSERACT_URL="https://github.com/tesseract-ocr/tesseract/archive/${TESSERACT_VERSION}.tar.gz"
LEPTONICA_URL="https://github.com/DanBloomberg/leptonica/archive/refs/tags/${LEPTONICA_VERSION}.tar.gz"
PNG_URL="https://download.sourceforge.net/libpng/libpng-${PNG_VERSION}.tar.gz"
ZLIB_URL="https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
ICU_URL="https://github.com/unicode-org/icu/releases/download/release-$(echo $ICU_VERSION | tr '.' '-')/icu4c-${ICU_VERSION/./_}-src.tgz"

# Compiler and linker settings
export CC="$(xcrun -f clang)"
export CXX="$(xcrun -f clang++)"
export CFLAGS="-arch arm64 -isysroot ${IOS_SDK} -miphoneos-version-min=${DEPLOYMENT_TARGET}"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-arch arm64 -isysroot ${IOS_SDK}"

# # Build zlib
# build_zlib() {
#     echo "Building zlib..."
#     wget "$ZLIB_URL"
#     tar -xvf "zlib-${ZLIB_VERSION}.tar.gz"
#     cd "zlib-${ZLIB_VERSION}"

#     ./configure \
#         --prefix="$OUTPUT_DIR" \
#         --static

#     make clean
#     make -j$(sysctl -n hw.ncpu)
#     make install
#     cd ..
# }

# Build libpng
# build_libpng() {
#     echo "Building libpng..."
#     wget "$PNG_URL"
#     tar -xvf "libpng-${PNG_VERSION}.tar.gz"
#     cd "libpng-${PNG_VERSION}"

#     mkdir -p build-arm64
#     cd build-arm64

#     ../configure \
#         --host="arm64-apple-darwin" \
#         --prefix="$OUTPUT_DIR" \
#         --enable-static \
#         --disable-shared \
#         CC="$CC" \
#         CFLAGS="${CFLAGS} -I${OUTPUT_DIR}/include" \
#         LDFLAGS="${LDFLAGS} -L${OUTPUT_DIR}/lib" \
#         --with-zlib-prefix="$OUTPUT_DIR"

#     make clean
#     make -j$(sysctl -n hw.ncpu)
#     make install
#     cd ../..
# }

# Build ICU
# build_icu() {
#     echo "Building ICU..."
#     wget "$ICU_URL"
#     tar -xvf "icu4c-${ICU_VERSION/./_}-src.tgz"
#     cd icu/source

#     ./configure \
#         --host="arm64-apple-darwin" \
#         --prefix="$OUTPUT_DIR" \
#         --enable-static \
#         --disable-shared \
#         --disable-samples \
#         --disable-tests \
#         CC="$CC" \
#         CXX="$CXX" \
#         CFLAGS="${CFLAGS}" \
#         CXXFLAGS="${CXXFLAGS}"

#     make clean
#     make -j$(sysctl -n hw.ncpu)
#     make install
#     cd ../..
# }

# Build Leptonica
# build_leptonica() {
#     echo "Building Leptonica..."
#     wget "$LEPTONICA_URL"
#     tar -xvf "${LEPTONICA_VERSION}.tar.gz"
#     cd "leptonica-${LEPTONICA_VERSION}"

#     ./autogen.sh
#     sed -i '' 's/SUBDIRS = src prog test/SUBDIRS = src prog/g' Makefile.am
#     autoreconf -fi

#     ./configure \
#         --host="arm64-apple-darwin" \
#         --prefix="$OUTPUT_DIR" \
#         --enable-static \
#         --disable-shared \
#         --with-zlib \
#         --with-libpng \
#         --disable-programs \
#         CC="$CC" \
#         CXX="$CXX" \
#         CFLAGS="${CFLAGS} -I${OUTPUT_DIR}/include" \
#         CPPFLAGS="-I${OUTPUT_DIR}/include" \
#         LDFLAGS="${LDFLAGS} -L${OUTPUT_DIR}/lib"

#     make clean
#     make -j$(sysctl -n hw.ncpu)
#     make install
#     cd ..
# }

# Build Tesseract
build_tesseract() {
    echo "Building Tesseract..."
    # wget "$TESSERACT_URL"
    # tar -xvf "${TESSERACT_VERSION}.tar.gz"
    cd "tesseract-${TESSERACT_VERSION}"

    echo "Leptonica Path: ${PNG_PATH}"
    ls "${PNG_PATH}/include"

    # 准备 autotools
    ./autogen.sh

    # 使用单行配置，去掉反斜杠和换行
    ./configure \
        --host=arm64-apple-darwin \
        --prefix="$OUTPUT_DIR" \
        --enable-static \
        --disable-shared \
        --disable-graphics \
        --disable-legacy \
        --without-curl \
        CC="$CC" \
        CXX="$CXX" \
        CFLAGS="${CFLAGS} -I${OUTPUT_DIR}/include -I${LEP_PATH}/include -I${HEAD_PATH} -I${PNG_PATH}/include -I${JPEG_PATH}/include -I${TIFF_PATH}/include -I${WEBP_PATH}/include -I${OPENJPEG_PATH}/include -I${IOS_SDK}/usr/include" \
        CXXFLAGS="${CXXFLAGS} -I${LEP_PATH}/include -I${PNG_PATH}/include -I${JPEG_PATH}/include -I${TIFF_PATH}/include -I${WEBP_PATH}/include -I${OPENJPEG_PATH}/include" \
        LDFLAGS="${LDFLAGS} -L${LEP_PATH}/lib -L${PNG_PATH}/lib -L${JPEG_PATH}/lib  -L${TIFF_PATH}/lib -L${WEBP_PATH}/lib -L${OPENJPEG_PATH}/lib -L${IOS_SDK}/usr/lib" \
        LEPTONICA_CFLAGS="-I${LEP_PATH}/include" \
        LEPTONICA_LIBS="-L${LEP_PATH}/lib -lleptonica" \
        PNG_CFLAGS="-I${PNG_PATH}/include" \
        PNG_LIBS="-L${PNG_PATH}/lib -lpng" \
        LIBARCHIVE_CFLAGS="-I${IOS_SDK}/usr/include" \
        LIBARCHIVE_LIBS="-L${IOS_SDK}/usr/lib -larchive" \
        JPEG_CFLAGS="-I${JPEG_PATH}/include" \
        JPEG_LIBS="-L${JPEG_PATH}/lib -ljpeg" \
        TIFF_CFLAGS="-I${TIFF_PATH}/include" \
        TIFF_LIBS="-L${TIFF_PATH}/lib -ltiff" \
        WEBP_CFLAGS="-I${WEBP_PATH}/include" \
        WEBP_LIBS="-L${WEBP_PATH}/lib -lwebp" \
        OPENJPEG_CFLAGS="-I${OPENJPEG_PATH}/include" \
        OPENJPEG_LIBS="-L${OPENJPEG_PATH}/lib -lopenjp2"

    make clean
    make -j$(sysctl -n hw.ncpu)
    make install
    cd ..
}
# Build dependencies and Tesseract
# build_zlib
# build_libpng
# build_icu
# build_leptonica
build_tesseract

# Verify libraries
echo "Verifying libraries..."
lipo -info "$OUTPUT_DIR/lib/libtesseract.a"
# lipo -info "$OUTPUT_DIR/lib/libleptonica.a"

# Optional: Clean up downloaded and extracted files
# rm -rf "zlib-${ZLIB_VERSION}" "libpng-${PNG_VERSION}" "icu" "leptonica-${LEPTONICA_VERSION}" "tesseract-${TESSERACT_VERSION}"
# rm "zlib-${ZLIB_VERSION}.tar.gz" "libpng-${PNG_VERSION}.tar.gz" "icu4c-${ICU_VERSION/./_}-src.tgz" "${LEPTONICA_VERSION}.tar.gz" "${TESSERACT_VERSION}.tar.gz"

echo "Tesseract OCR iOS library built successfully in $OUTPUT_DIR"