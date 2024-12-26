#!/bin/bash

# 设置版本
WEBP_VERSION="1.3.2"

# 下载地址
WEBP_URL="https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${WEBP_VERSION}.tar.gz"

# iOS 编译配置
DEVELOPER_ROOT="/Applications/Xcode.app/Contents/Developer"
IOS_SDK="${DEVELOPER_ROOT}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
DEPLOYMENT_TARGET="15.0"

# 输出目录
OUTPUT_DIR="$(pwd)/ios-libraries/libwebp-ios"
mkdir -p "$OUTPUT_DIR"

# 设置编译器和标志
export CC="$(xcrun -f clang)"
export CXX="$(xcrun -f clang++)"
export CFLAGS="-arch arm64 -isysroot ${IOS_SDK} -miphoneos-version-min=${DEPLOYMENT_TARGET} -fembed-bitcode"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-arch arm64 -isysroot ${IOS_SDK}"

# 编译 libwebp
build_libwebp() {
    echo "Building libwebp..."
    wget "$WEBP_URL"
    tar -xvf "libwebp-${WEBP_VERSION}.tar.gz"
    cd "libwebp-${WEBP_VERSION}"

    # 创建构建目录
    mkdir -p build-ios
    cd build-ios

    # 配置 libwebp
    ../configure \
        --host=arm-apple-darwin \
        --prefix="$OUTPUT_DIR" \
        --enable-static \
        --disable-shared \
        --disable-dependency-tracking \
        --disable-gl \
        --disable-sdl \
        --disable-png \
        --disable-jpeg \
        --disable-tiff \
        --disable-gif

    make clean
    make -j$(sysctl -n hw.ncpu)
    make install

    cd ../..
}

# 清理旧的构建
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 执行构建
build_libwebp

# 验证库
if [ -f "$OUTPUT_DIR/lib/libwebp.a" ]; then
    echo "Verifying libwebp.a..."
    lipo -info "$OUTPUT_DIR/lib/libwebp.a"
else
    echo "Error: libwebp.a was not built successfully"
    exit 1
fi

# 清理
rm -rf "libwebp-${WEBP_VERSION}"
rm -f "libwebp-${WEBP_VERSION}.tar.gz"

echo "libwebp iOS libraries built successfully in $OUTPUT_DIR"