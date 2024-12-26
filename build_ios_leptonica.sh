#!/bin/bash

# 设置 Leptonica 版本
LEPTONICA_VERSION="1.85.0"

# iOS 编译配置
DEVELOPER_ROOT="/Applications/Xcode.app/Contents/Developer"
IOS_SDK="${DEVELOPER_ROOT}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
DEPLOYMENT_TARGET="15.0"

# 依赖库版本
PNG_VERSION="1.6.40"
ZLIB_VERSION="1.3.1"

# 输出目录 (使用绝对路径)
OUTPUT_DIR="$(pwd)/ios-libraries/leptonica-ios"
mkdir -p "$OUTPUT_DIR"

# 下载地址
LEPTONICA_URL="https://github.com/DanBloomberg/leptonica/archive/refs/tags/${LEPTONICA_VERSION}.tar.gz"
PNG_URL="https://download.sourceforge.net/libpng/libpng-${PNG_VERSION}.tar.gz"
ZLIB_URL="https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz"

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

# 编译 Leptonica
# 在 build_leptonica() 函数之前添加
build_leptonica() {
    # 下载 Leptonica
    wget "$LEPTONICA_URL"
    tar -xvf "${LEPTONICA_VERSION}.tar.gz"
    cd "leptonica-${LEPTONICA_VERSION}"

    # 准备编译
    ./autogen.sh

    # 修补以禁用使用 system() 的测试
    # 这将阻止编译可能使用不可用函数的测试
    sed -i '' 's/SUBDIRS = src prog test/SUBDIRS = src prog/g' Makefile.am
    autoreconf -fi

    # 配置编译选项
    CFLAGS="-arch arm64 -isysroot ${IOS_SDK} -miphoneos-version-min=${DEPLOYMENT_TARGET}" \
    CPPFLAGS="-I${OUTPUT_DIR}/include" \
    LDFLAGS="-L${OUTPUT_DIR}/lib" \
    ./configure \
        --host="arm64-apple-darwin" \
        --prefix="$OUTPUT_DIR" \
        --enable-static \
        --disable-shared \
        --with-zlib \
        --with-libpng \
        --disable-programs \  # 可选：如果不需要程序，也可以禁用
        CC="$(xcrun -f clang)" \
        CXX="$(xcrun -f clang++)"

    # 编译
    make clean
    make -j$(sysctl -n hw.ncpu)
    make install

    cd ..
}

# 编译依赖库和 Leptonica
# build_zlib
# build_libpng
build_leptonica

# 验证库
lipo -info "$OUTPUT_DIR/lib/libleptonica.a"

# 清理
# rm -rf "zlib-${ZLIB_VERSION}" "libpng-${PNG_VERSION}" "leptonica-${LEPTONICA_VERSION}"
# rm "zlib-${ZLIB_VERSION}.tar.gz" "libpng-${PNG_VERSION}.tar.gz" "${LEPTONICA_VERSION}.tar.gz"

echo "Leptonica iOS library built successfully in $OUTPUT_DIR"