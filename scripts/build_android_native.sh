#!/usr/bin/env bash
set -e

# Detect NDK
NDK_VERSION="26.1.10909125"
if [ -z "$ANDROID_NDK_HOME" ]; then
  if [ -d "/home/maheer-wsl/android-sdk/ndk/$NDK_VERSION" ]; then
    export ANDROID_NDK_HOME="/home/maheer-wsl/android-sdk/ndk/$NDK_VERSION"
  elif [ -d "$HOME/android-sdk/ndk/$NDK_VERSION" ]; then
    export ANDROID_NDK_HOME="$HOME/android-sdk/ndk/$NDK_VERSION"
  fi
fi

export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/home/maheer-wsl/.cargo-target/reliq}"

echo "Building reliq_native for Android architectures (arm64-v8a, armeabi-v7a, x86_64)..."
cd "$(dirname "$0")/../native"

cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -o ../android/app/src/main/jniLibs build --release

echo "Successfully built and copied libreliq_native.so to android/app/src/main/jniLibs!"

