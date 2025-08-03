#!/bin/bash

set -e

FRAMEWORK_NAME="SemanticKernel"

# Abstractions
ABSTRACTIONS_FRAMEWORK_NAME="SemanticKernelAbstractions"
ABSTRACTIONS_SCHEME_NAME="SemanticKernelAbstractions"

# Core
CORE_FRAMEWORK_NAME="SemanticKernelCore"
CORE_SCHEME_NAME="SemanticKernelCore"

# Connectors
OPENAI_FRAMEWORK_NAME="SemanticKernelConnectorsOpenAI"
OPENAI_SCHEME_NAME="SemanticKernelConnectorsOpenAI"
AZURE_OPENAI_FRAMEWORK_NAME="SemanticKernelConnectorsAzureOpenAI"
AZURE_OPENAI_SCHEME_NAME="SemanticKernelConnectorsAzureOpenAI"
QDRANT_FRAMEWORK_NAME="SemanticKernelConnectorsQdrant"
QDRANT_SCHEME_NAME="SemanticKernelConnectorsQdrant"

# Plugins
PLUGINS_CORE_FRAMEWORK_NAME="SemanticKernelPluginsCore"
PLUGINS_CORE_SCHEME_NAME="SemanticKernelPluginsCore"


FRAMEWORKS=("$ABSTRACTIONS_FRAMEWORK_NAME" "$CORE_FRAMEWORK_NAME" "$OPENAI_FRAMEWORK_NAME" "$AZURE_OPENAI_FRAMEWORK_NAME" "$QDRANT_FRAMEWORK_NAME" "$PLUGINS_CORE_FRAMEWORK_NAME")
SCHEMES=("$ABSTRACTIONS_SCHEME_NAME" "$CORE_SCHEME_NAME" "$OPENAI_SCHEME_NAME" "$AZURE_OPENAI_SCHEME_NAME" "$QDRANT_SCHEME_NAME" "$PLUGINS_CORE_SCHEME_NAME")

BUILD_DIR="$(pwd)/build"

# Clean up previous builds
rm -rf .build
rm -rf *.xcarchive
rm -rf *.xcframework
rm -rf $BUILD_DIR

mkdir -p $BUILD_DIR

# Build for each platform
for i in ${!FRAMEWORKS[@]}; do
    FRAMEWORK_NAME=${FRAMEWORKS[$i]}
    SCHEME_NAME=${SCHEMES[$i]}

    echo "Building $FRAMEWORK_NAME for iOS"
    xcodebuild archive \
        -scheme "$SCHEME_NAME" \
        -destination "generic/platform=iOS" \
        -archivePath "$BUILD_DIR/$FRAMEWORK_NAME-iOS.xcarchive" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SWIFT_STRICT_CONCURRENCY=OFF
    find "$BUILD_DIR/$FRAMEWORK_NAME-iOS.xcarchive" -name "*.framework"

    echo "Building $FRAMEWORK_NAME for macOS"
    xcodebuild archive \
        -scheme "$SCHEME_NAME" \
        -destination "generic/platform=macOS" \
        -archivePath "$BUILD_DIR/$FRAMEWORK_NAME-macOS.xcarchive" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SWIFT_STRICT_CONCURRENCY=OFF
    find "$BUILD_DIR/$FRAMEWORK_NAME-macOS.xcarchive" -name "*.framework"

    echo "Building $FRAMEWORK_NAME for watchOS"
    xcodebuild archive \
        -scheme "$SCHEME_NAME" \
        -destination "generic/platform=watchOS" \
        -archivePath "$BUILD_DIR/$FRAMEWORK_NAME-watchOS.xcarchive" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SWIFT_STRICT_CONCURRENCY=OFF
    find "$BUILD_DIR/$FRAMEWORK_NAME-watchOS.xcarchive" -name "*.framework"

    echo "Building $FRAMEWORK_NAME for tvOS"
    xcodebuild archive \
        -scheme "$SCHEME_NAME" \
        -destination "generic/platform=tvOS" \
        -archivePath "$BUILD_DIR/$FRAMEWORK_NAME-tvOS.xcarchive" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SWIFT_STRICT_CONCURRENCY=OFF
    find "$BUILD_DIR/$FRAMEWORK_NAME-tvOS.xcarchive" -name "*.framework"

    # Create XCFramework
    # This part will be updated once the correct paths are identified
    # xcodebuild -create-xcframework \
    #     -framework "$BUILD_DIR/$FRAMEWORK_NAME-iOS.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    #     -framework "$BUILD_DIR/$FRAMEWORK_NAME-macOS.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    #     -framework "$BUILD_DIR/$FRAMEWORK_NAME-watchOS.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    #     -framework "$BUILD_DIR/$FRAMEWORK_NAME-tvOS.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    #     -output "$BUILD_DIR/$FRAMEWORK_NAME.xcframework"
done