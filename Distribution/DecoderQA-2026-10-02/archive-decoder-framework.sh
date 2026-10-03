#!/bin/bash
# Framework only, from an already-built isolated source tree. Never uploads.
set -euo pipefail
decoder_stage="${1:?Provide the isolated decoder build directory}"
decoder_sdk="${2:?Provide one exact Apple SDK name}"
case "$decoder_stage" in /*) ;; *) exit 2 ;; esac
test -f "$decoder_stage/VLCKit/VLCKit.xcodeproj/project.pbxproj"
case "$decoder_sdk" in
  iphoneos) decoder_platform='iOS'; decoder_minimum='IPHONEOS_DEPLOYMENT_TARGET=18.0' ;;
  iphonesimulator) decoder_platform='iOS Simulator'; decoder_minimum='IPHONEOS_DEPLOYMENT_TARGET=18.0' ;;
  appletvos) decoder_platform='tvOS'; decoder_minimum='TVOS_DEPLOYMENT_TARGET=18.0' ;;
  appletvsimulator) decoder_platform='tvOS Simulator'; decoder_minimum='TVOS_DEPLOYMENT_TARGET=18.0' ;;
  xros) decoder_platform='visionOS'; decoder_minimum='XROS_DEPLOYMENT_TARGET=2.0' ;;
  xrsimulator) decoder_platform='visionOS Simulator'; decoder_minimum='XROS_DEPLOYMENT_TARGET=2.0' ;;
  *) printf 'Unsupported SDK\n' >&2; exit 2 ;;
esac
cd "$decoder_stage/VLCKit"
xcodebuild archive -project VLCKit.xcodeproj -scheme VLCKit -configuration Release \
    -sdk "$decoder_sdk" -destination "generic/platform=$decoder_platform" \
    -archivePath "build/VLCKit-$decoder_sdk.xcarchive" \
    ARCHS=arm64 ONLY_ACTIVE_ARCH=NO SKIP_INSTALL=NO CODE_SIGNING_ALLOWED=NO "$decoder_minimum"
