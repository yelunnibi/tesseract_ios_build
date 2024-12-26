#!/bin/bash

# 设置版本
OPENJPEG_VERSION="2.5.0"

# 下载地址
OPENJPEG_URL="https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}.tar.gz"

# iOS 编译配置
DEVELOPER_ROOT="/Applications/Xcode.app/Contents/Developer"
IOS_SDK="${DEVELOPER_ROOT}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
DEPLOYMENT_TARGET="15.0"

# 输出目录
OUTPUT_DIR="$(pwd)/ios-libraries/libopenjpeg-ios"
mkdir -p "$OUTPUT_DIR"

# 设置编译器和标志
export CC="$(xcrun -f clang)"
export CXX="$(xcrun -f clang++)"
export CFLAGS="-arch arm64 -isysroot ${IOS_SDK} -miphoneos-version-min=${DEPLOYMENT_TARGET} -fembed-bitcode"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-arch arm64 -isysroot ${IOS_SDK}"

# 编译 OpenJPEG
build_openjpeg() {
    echo "Building OpenJPEG..."
    # wget "$OPENJPEG_URL" -O "openjpeg-${OPENJPEG_VERSION}.tar.gz"
    tar -xvf "openjpeg-${OPENJPEG_VERSION}.tar.gz"
    cd "openjpeg-${OPENJPEG_VERSION}"

    # 创建构建目录
    mkdir -p build-ios
    cd build-ios

    # 配置 OpenJPEG (使用 CMake)
    cmake .. \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=${DEPLOYMENT_TARGET} \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_OSX_SYSROOT=${IOS_SDK} \
        -DCMAKE_INSTALL_PREFIX=${OUTPUT_DIR} \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_STATIC_LIBS=ON \
        -DBUILD_PKGCONFIG_FILES=OFF \
        -DBUILD_TESTING=OFF \
        -DBUILD_CODEC=OFF \
        -DBUILD_MJ2=OFF \
        -DBUILD_JPWL=OFF \
        -DBUILD_JPIP=OFF \
        -DBUILD_JP3D=OFF \
        -DBUILD_JAVA=OFF \
        -DBUILD_DOC=OFF

    # 编译
    make clean
    make -j$(sysctl -n hw.ncpu)
    make install

    cd ../..
}

# 清理旧的构建
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 执行构建
build_openjpeg

# 验证库
if [ -f "$OUTPUT_DIR/lib/libopenjp2.a" ]; then
    echo "Verifying libopenjp2.a..."
    lipo -info "$OUTPUT_DIR/lib/libopenjp2.a"
else
    echo "Error: libopenjp2.a was not built successfully"
    exit 1
fi

# 清理
rm -rf "openjpeg-${OPENJPEG_VERSION}"
# rm -f "openjpeg-${OPENJPEG_VERSION}.tar.gz"

echo "OpenJPEG iOS libraries built successfully in $OUTPUT_DIR"