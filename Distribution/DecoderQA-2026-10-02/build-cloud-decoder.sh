#!/bin/bash
# Rebuild the decoder on the explicitly requested stable Cloud toolchain.
# Never consume a local/beta-built framework and never upload from this script.
set -euo pipefail
case "${CI:-}" in
    true|TRUE) ;;
    *) printf 'Cloud-only release dependency build\n' >&2; exit 2 ;;
esac
decoder_xcode="$(xcodebuild -version)"
test "$decoder_xcode" = $'Xcode 27.0\nBuild version 27A266a' ||
test "$decoder_xcode" = $'Xcode 27\nBuild version 27A266a' || {
    printf 'Expected stable Xcode 27.0 (27A266a); refusing dependency build\n' >&2; exit 2;
}
qa_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$qa_dir/../.." && pwd)"
decoder_platform="${CI_PRODUCT_PLATFORM:?Cloud platform is required}"
# Apple /bin/bash 3.2 treats an empty array expansion as unset under -u.
# Keep the complete argument vector nonempty on every platform.
decoder_flags=(-r -a aarch64)
case "$decoder_platform" in
    iOS) decoder_device=iphoneos; decoder_sim=iphonesimulator ;;
    tvOS) decoder_device=appletvos; decoder_sim=appletvsimulator; decoder_flags+=(-t) ;;
    xrOS|visionOS) decoder_device=xros; decoder_sim=xrsimulator; decoder_flags+=(-i) ;;
    *) printf 'Unsupported Cloud platform\n' >&2; exit 2 ;;
esac
test ! -e "$repo_dir/Dependencies/VLCKit.xcframework" || {
    printf 'Decoder destination must be absent in a clean checkout\n' >&2; exit 2;
}
decoder_stage="$(mktemp -d "${TMPDIR:-/tmp}/xplay-cloud-decoder.XXXXXX")"
readonly decoder_stage
git clone --no-checkout https://code.videolan.org/videolan/VLCKit.git "$decoder_stage/VLCKit"
git -C "$decoder_stage/VLCKit" checkout --detach 5d3535a664e7815765a5cee40d9b22527d7299cc
git clone --no-checkout https://code.videolan.org/videolan/vlc.git "$decoder_stage/vlc"
git -C "$decoder_stage/vlc" checkout --detach c9628afc4b221b171ec2d9e028782b9eb1247426
decoder_patch_count=0
for decoder_patch in "$decoder_stage/VLCKit/libvlc/patches/"*.patch; do
    git -C "$decoder_stage/vlc" apply "$decoder_patch"
    decoder_patch_count=$((decoder_patch_count + 1))
done
test "$decoder_patch_count" -eq 20
git -C "$decoder_stage/vlc" apply "$qa_dir/vlc-truehd.patch"
git -C "$decoder_stage/vlc" apply "$qa_dir/vlc-ass-fallback.patch"
git -C "$decoder_stage/VLCKit" apply "$qa_dir/vlckit-apple-arm64.patch"
export HOMEBREW_NO_AUTO_UPDATE=1
brew install autoconf automake libtool pkg-config cmake ninja meson nasm gettext gperf bison flex python node
node "$qa_dir/stamp-modifications.cjs" "$decoder_stage"
# The wrapper's final packaging assumes old deployment targets and Intel sims.
# Build only the static inputs with it, then archive the two frameworks explicitly.
awk '{ print; if ($0 == "shift $(($OPTIND - 1))") print "BUILD_FRAMEWORK=no" }' \
    "$decoder_stage/VLCKit/compileAndBuildVLCKit.sh" > "$decoder_stage/VLCKit/compile-cloud.sh"
ln -s "$decoder_stage/vlc" "$decoder_stage/VLCKit/libvlc/vlc"
export VLC_PATH="$(brew --prefix)/bin:$(brew --prefix bison)/bin:$(brew --prefix flex)/bin:$(brew --prefix gettext)/bin"
export MAKEFLAGS=-j6
(
    cd "$decoder_stage/VLCKit"
    bash ./compile-cloud.sh "${decoder_flags[@]}" -v -e "$decoder_stage/vlc"
)
for decoder_sdk in "$decoder_device" "$decoder_sim"; do
    bash "$qa_dir/archive-decoder-framework.sh" "$decoder_stage" "$decoder_sdk"
    decoder_binary="$decoder_stage/VLCKit/build/VLCKit-$decoder_sdk.xcarchive/Products/Library/Frameworks/VLCKit.framework/VLCKit"
    # Registration, not just a decoder name in strings. Runtime PCM verification
    # is a separate release gate; these symbol checks cannot substitute for it.
    nm -gU "$decoder_binary" | grep ' _ff_truehd_decoder$' > /dev/null
    nm -gU "$decoder_binary" | grep ' _avcodec_find_decoder_by_name$' > /dev/null
    xcrun vtool -show-build "$decoder_binary"
    dwarfdump --uuid "$decoder_binary"
done
decoder_ffmpeg_archive="$decoder_stage/vlc/contrib/tarballs/ffmpeg-8.1.2.tar.xz"
test -f "$decoder_ffmpeg_archive"
decoder_ffmpeg_hash="$(shasum -a 256 "$decoder_ffmpeg_archive")"
test "${decoder_ffmpeg_hash%% *}" = 464beb5e7bf0c311e68b45ae2f04e9cc2af88851abb4082231742a74d97b524c
decoder_config_count=0
while IFS= read -r decoder_config; do
    for decoder_disabled in GPL NONFREE VERSION3; do
        grep -x "#define CONFIG_$decoder_disabled 0" "$decoder_config" > /dev/null
    done
    grep -x '#define CONFIG_TRUEHD_DECODER 1' "$(dirname "$decoder_config")/config_components.h" > /dev/null
    decoder_config_count=$((decoder_config_count + 1))
done < <(find "$decoder_stage/vlc/contrib" -type f -path '*/ffmpeg/vlc_build/config.h')
test "$decoder_config_count" -eq 2
mkdir -p "$repo_dir/Dependencies"
xcodebuild -create-xcframework \
    -framework "$decoder_stage/VLCKit/build/VLCKit-$decoder_device.xcarchive/Products/Library/Frameworks/VLCKit.framework" \
    -debug-symbols "$decoder_stage/VLCKit/build/VLCKit-$decoder_device.xcarchive/dSYMs/VLCKit.framework.dSYM" \
    -framework "$decoder_stage/VLCKit/build/VLCKit-$decoder_sim.xcarchive/Products/Library/Frameworks/VLCKit.framework" \
    -debug-symbols "$decoder_stage/VLCKit/build/VLCKit-$decoder_sim.xcarchive/dSYMs/VLCKit.framework.dSYM" \
    -output "$repo_dir/Dependencies/VLCKit.xcframework"
printf 'Stable Cloud decoder built for %s; App archive/upload not performed by this script.\n' "$decoder_platform"
