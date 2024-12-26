#!/bin/bash

# 设置版本
ZLIB_VERSION="1.3.1"
TIFF_VERSION="4.5.0"

# 下载地址
ZLIB_URL="https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
TIFF_URL="http://download.osgeo.org/libtiff/tiff-${TIFF_VERSION}.tar.gz"

# iOS 编译配置
DEVELOPER_ROOT="/Applications/Xcode.app/Contents/Developer"
IOS_SDK="${DEVELOPER_ROOT}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
DEPLOYMENT_TARGET="15.0"

# 输出目录
OUTPUT_DIR="$(pwd)/ios-libraries/libtiff-ios"
mkdir -p "$OUTPUT_DIR"

# 设置编译器和标志
export CC="$(xcrun -f clang)"
export CXX="$(xcrun -f clang++)"
export CFLAGS="-arch arm64 -isysroot ${IOS_SDK} -miphoneos-version-min=${DEPLOYMENT_TARGET} -fembed-bitcode"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-arch arm64 -isysroot ${IOS_SDK}"

# 编译 zlib
build_zlib() {
    echo "Building zlib..."
    wget "$ZLIB_URL"
    tar -xvf "zlib-${ZLIB_VERSION}.tar.gz"
    cd "zlib-${ZLIB_VERSION}"

    # 配置 zlib
    export CFLAGS="${CFLAGS} -O3"
    ./configure \
        --prefix="$OUTPUT_DIR" \
        --static

    make clean
    make -j$(sysctl -n hw.ncpu)
    make install

    cd ..
}

# 编译 libtiff
build_libtiff() {
    echo "Building libtiff..."
    wget "$TIFF_URL"
    tar -xvf "tiff-${TIFF_VERSION}.tar.gz"
    cd "tiff-${TIFF_VERSION}"

    # 重置 CFLAGS
    export CFLAGS="-arch arm64 -isysroot ${IOS_SDK} -miphoneos-version-min=${DEPLOYMENT_TARGET} -fembed-bitcode -I${OUTPUT_DIR}/include"
    export LDFLAGS="-arch arm64 -isysroot ${IOS_SDK} -L${OUTPUT_DIR}/lib"

    # 创建构建目录
    mkdir -p build-ios
    cd build-ios

    # 配置 libtiff
    ../configure \
        --host=arm-apple-darwin \
        --prefix="$OUTPUT_DIR" \
        --enable-static \
        --disable-shared \
        --disable-cxx \
        --disable-jbig \
        --disable-lzma \
        --disable-webp \
        --disable-zstd \
        --with-zlib-include-dir="${OUTPUT_DIR}/include" \
        --with-zlib-lib-dir="${OUTPUT_DIR}/lib"

    make clean
    make -j$(sysctl -n hw.ncpu)
    make install

    cd ../..
}

# 清理旧的构建
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 执行构建
build_zlib
build_libtiff

# 验证库
if [ -f "$OUTPUT_DIR/lib/libtiff.a" ]; then
    echo "Verifying libtiff.a..."
    lipo -info "$OUTPUT_DIR/lib/libtiff.a"
else
    echo "Error: libtiff.a was not built successfully"
    exit 1
fi

# 清理
rm -rf "zlib-${ZLIB_VERSION}" "tiff-${TIFF_VERSION}"
rm -f "zlib-${ZLIB_VERSION}.tar.gz" "tiff-${TIFF_VERSION}.tar.gz"

echo "libtiff iOS libraries built successfully in $OUTPUT_DIR"