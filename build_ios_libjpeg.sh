#!/bin/bash

# 设置错误处理
set -e  # 遇到错误立即退出
set -o pipefail  # 管道中任何命令失败都视为整体失败

# 设置 libjpeg 版本
JPEG_VERSION="9f"

# 下载地址
JPEG_URL="https://www.ijg.org/files/jpegsrc.v${JPEG_VERSION}.tar.gz"

# iOS 编译配置
DEVELOPER_ROOT="/Applications/Xcode.app/Contents/Developer"
IOS_SDK="${DEVELOPER_ROOT}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
DEPLOYMENT_TARGET="15.0"

# 输出目录 (使用绝对路径)
OUTPUT_DIR="$(pwd)/ios-libraries/libjpeg-ios"

# 错误处理函数
error_exit() {
    echo "❌ Error: $1" >&2
    exit 1
}

# 清理函数
cleanup() {
    if [ $? -ne 0 ]; then
        echo "❌ Build process failed. Cleaning up..."
        rm -rf "jpeg-${JPEG_VERSION}" "jpegsrc.v${JPEG_VERSION}.tar.gz"
    fi
}
trap cleanup EXIT

# 预检查
pre_check() {
    # 检查必要工具
    command -v wget >/dev/null 2>&1 || error_exit "wget is not installed. Please install via Homebrew: brew install wget"
    command -v xcode-select >/dev/null 2>&1 || error_exit "Xcode command-line tools are not installed"
    
    # 检查 SDK 是否存在
    [ -d "${IOS_SDK}" ] || error_exit "iOS SDK not found at ${IOS_SDK}"
}

# 准备编译目录
prepare_build_dir() {
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR" || error_exit "Failed to create output directory"
}

# 编译 libjpeg
build_libjpeg() {
    # 下载 libjpeg
    wget -O "jpegsrc.v${JPEG_VERSION}.tar.gz" "$JPEG_URL" || error_exit "Failed to download libjpeg source"
    
    # 解压
    tar -xvf "jpegsrc.v${JPEG_VERSION}.tar.gz" || error_exit "Failed to extract libjpeg source"
    
    cd "jpeg-${JPEG_VERSION}" || error_exit "Cannot change to jpeg source directory"

    # 创建编译目录
    mkdir -p build-arm64
    cd build-arm64 || error_exit "Cannot change to build directory"

    # 配置编译选项 (只针对 arm64)
    ../configure \
        --host="arm64-apple-darwin" \
        --prefix="$OUTPUT_DIR" \
        --enable-static \
        --disable-shared \
        CC="$(xcrun -f clang)" \
        CFLAGS="-arch arm64 -isysroot ${IOS_SDK} -miphoneos-version-min=${DEPLOYMENT_TARGET}" \
        CPPFLAGS="-I${IOS_SDK}/usr/include" \
        LDFLAGS="-arch arm64 -isysroot ${IOS_SDK}" || error_exit "Configure failed"

    # 编译
    make clean
    make -j$(sysctl -n hw.ncpu) || error_exit "Compilation failed"
    make install || error_exit "Installation failed"

    cd ../..
}

# 验证库
verify_library() {
    # 检查静态库是否存在
    [ -f "$OUTPUT_DIR/lib/libjpeg.a" ] || error_exit "libjpeg.a not found after installation"
    
    # 验证库架构
    lipo -info "$OUTPUT_DIR/lib/libjpeg.a" || error_exit "Failed to verify library architecture"
}

# 主执行流程
main() {
    pre_check
    prepare_build_dir
    build_libjpeg
    verify_library
    
    # 清理下载的源代码
    rm -rf "jpeg-${JPEG_VERSION}" "jpegsrc.v${JPEG_VERSION}.tar.gz"

    echo "✅ libjpeg iOS library built successfully in $OUTPUT_DIR"
}

# 执行主流程
main
