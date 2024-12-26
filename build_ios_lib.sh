#!/bin/bash

# 设置版本
PNG_VERSION="1.6.40"
JPEG_VERSION="9f"
TIFF_VERSION="4.6.0"
WEBP_VERSION="1.3.2"
GIF_VERSION="5.2.1"
OPENJPEG_VERSION="2.5.0"

# 设置 iOS SDK 路径
DEVELOPER_ROOT="/Applications/Xcode.app/Contents/Developer"
IPHONEOS_SDK="${DEVELOPER_ROOT}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"

# 创建库目录
LIBS_DIR="$HOME/ios-libraries-arm64"
mkdir -p $LIBS_DIR
cd $LIBS_DIR

# 通用编译函数
build_library() {
    local NAME=$1
    local VERSION=$2
    local DOWNLOAD_URL=$3
    local CONFIGURE_OPTIONS=${4:-""}
    local BUILD_TYPE=${5:-"autotools"}

    echo "Building $NAME $VERSION..."
    
    # 下载并解压
    wget "$DOWNLOAD_URL"
    tar -xvf "${NAME}-${VERSION}.tar.gz"
    cd "${NAME}-${VERSION}"

    # 准备编译环境
    export IPHONEOS_DEPLOYMENT_TARGET="13.0"
    
    if [ "$BUILD_TYPE" == "autotools" ]; then
        # Autotools 编译
        ./configure \
            --host=arm-apple-darwin \
            --prefix="$LIBS_DIR/$NAME" \
            --enable-static \
            --disable-shared \
            CC="$(xcrun -f clang)" \
            CFLAGS="-arch arm64 -isysroot $IPHONEOS_SDK -miphoneos-version-min=13.0" \
            LDFLAGS="-arch arm64 -isysroot $IPHONEOS_SDK" \
            $CONFIGURE_OPTIONS

        make clean
        make -j$(sysctl -n hw.ncpu)
        make install
    elif [ "$BUILD_TYPE" == "cmake" ]; then
        # CMake 编译
        cmake -B build \
            -DCMAKE_SYSTEM_NAME=iOS \
            -DCMAKE_OSX_ARCHITECTURES=arm64 \
            -DCMAKE_OSX_SYSROOT=$IPHONEOS_SDK \
            -DCMAKE_INSTALL_PREFIX="$LIBS_DIR/$NAME" \
            -DBUILD_SHARED_LIBS=OFF \
            $CONFIGURE_OPTIONS

        cmake --build build -j$(sysctl -n hw.ncpu)
        cmake --install build
    fi

    cd ..
}

# 编译 libpng
build_library "libpng" "$PNG_VERSION" \
    "https://download.sourceforge.net/libpng/libpng-${PNG_VERSION}.tar.gz"

# 编译 libjpeg-turbo
build_library "libjpeg" "$JPEG_VERSION" \
    "https://sourceforge.net/projects/libjpeg-turbo/files/${JPEG_VERSION}/libjpeg-turbo-${JPEG_VERSION}.tar.gz"

# 编译 libtiff
build_library "libtiff" "$TIFF_VERSION" \
    "https://download.osgeo.org/libtiff/tiff-${TIFF_VERSION}.tar.gz"

# 编译 libwebp
build_library "libwebp" "$WEBP_VERSION" \
    "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${WEBP_VERSION}.tar.gz"

# 编译 giflib
build_library "giflib" "$GIF_VERSION" \
    "https://sourceforge.net/projects/giflib/files/giflib-${GIF_VERSION}.tar.gz"

# 编译 OpenJPEG (使用 CMake)
build_library "openjpeg" "$OPENJPEG_VERSION" \
    "https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}.tar.gz" \
    "" "cmake"

# 打印库位置
echo "Libraries built in $LIBS_DIR"
