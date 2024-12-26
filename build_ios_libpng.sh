#!/bin/bash

# 设置 libpng 和 zlib 版本
PNG_VERSION="1.6.40"
ZLIB_VERSION="1.3.1"

# 下载地址
PNG_URL="https://download.sourceforge.net/libpng/libpng-${PNG_VERSION}.tar.gz"
ZLIB_URL="https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz"

# iOS 编译配置
DEVELOPER_ROOT="/Applications/Xcode.app/Contents/Developer"
IOS_SDK="${DEVELOPER_ROOT}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
DEPLOYMENT_TARGET="15.0"

# 输出目录 (使用绝对路径)
OUTPUT_DIR="$(pwd)/ios-libraries/libpng-ios"
mkdir -p "$OUTPUT_DIR"

# 编译 zlib
build_zlib() {
    # 下载 zlib
    wget "$ZLIB_URL"
    tar -xvf "zlib-${ZLIB_VERSION}.tar.gz"
    cd "zlib-${ZLIB_VERSION}"

    # 配置 zlib
    CFLAGS="-arch arm64 -isysroot ${IOS_SDK} -miphoneos-version-min=${DEPLOYMENT_TARGET}" \
    ./configure \
        --prefix="$OUTPUT_DIR" \
        --static

    make clean
    make -j$(sysctl -n hw.ncpu)
    make install

    cd ..
}

# 编译 libpng
build_libpng() {
    # 下载 libpng
    wget "$PNG_URL"
    tar -xvf "libpng-${PNG_VERSION}.tar.gz"
    cd "libpng-${PNG_VERSION}"

    mkdir -p build-arm64
    cd build-arm64

    # 配置编译选项 (只针对 arm64)
    ../configure \
        --host="arm64-apple-darwin" \
        --prefix="$OUTPUT_DIR" \
        --enable-static \
        --disable-shared \
        CC="$(xcrun -f clang)" \
        CFLAGS="-arch arm64 -isysroot ${IOS_SDK} -miphoneos-version-min=${DEPLOYMENT_TARGET} -I${OUTPUT_DIR}/include -I${IOS_SDK}/usr/include" \
        CPPFLAGS="-I${OUTPUT_DIR}/include -I${IOS_SDK}/usr/include" \
        LDFLAGS="-arch arm64 -isysroot ${IOS_SDK} -L${OUTPUT_DIR}/lib" \
        --with-zlib-prefix="$OUTPUT_DIR"

    # 编译
    make clean
    make -j$(sysctl -n hw.ncpu)
    make install

    cd ../..
}

# 先编译 zlib，再编译 libpng
build_zlib
build_libpng

# 验证库
lipo -info "$OUTPUT_DIR/lib/libpng.a"

# 清理
rm -rf "zlib-${ZLIB_VERSION}" "libpng-${PNG_VERSION}"
rm "zlib-${ZLIB_VERSION}.tar.gz" "libpng-${PNG_VERSION}.tar.gz"

echo "libpng iOS library built successfully in $OUTPUT_DIR"