# X Play decoder source and build materials

Corresponding open-source playback-library materials for the proposed X Play
3.02 (70) release. This repository contains no proprietary X Play application
source, account data, signing credentials, media, or application diagnostics.
Publication of source materials does not imply that an App Store build has
completed or passed review.

## Sources and modifications

- VLCKit: `5d3535a664e7815765a5cee40d9b22527d7299cc`
  from https://code.videolan.org/videolan/VLCKit
- VLC: `c9628afc4b221b171ec2d9e028782b9eb1247426`
  from https://code.videolan.org/videolan/vlc, with the 20 patches supplied by
  that VLCKit revision, followed by the two VLC patches in this repository.
- FFmpeg: 8.1.2 source archive, SHA-256
  `464beb5e7bf0c311e68b45ae2f04e9cc2af88851abb4082231742a74d97b524c`.
- Other dependency versions and patches are defined in the included VLC
  `contrib/src` tree. The source bundle also contains dependency source archives
  and a SHA-256 inventory, not just links to upstream repositories.

X Play changes, 2026-10-02:

- Enable the FFmpeg TrueHD/MLP software decoder in the Apple build.
- Supply the configured font family to the Apple libass fallback path, retaining
  explicitly requested and embedded ASS fonts ahead of the fallback.
- Correct arm64 device/simulator selection and visionOS static-module registration;
  remove the obsolete visionOS linker flag.
- Build framework slices explicitly for iOS/tvOS 18 and visionOS 2 or newer.

The modifications remain under the affected upstream file's license. VLCKit
and the libVLC library are LGPL-2.1-or-later; individual third-party components
retain their own copyright and license notices. See `COPYING.LGPL-2.1` and the
complete license files in the source bundle. No warranty is provided.

## Download full source

The `xplay-3.02-70` GitHub release provides `xplay-decoder-3.02-70-source.tar.gz`
and its SHA-256 file. It contains clean source trees with these patches applied,
their original license notices, dependency archives, and the build scripts.
It contains no prebuilt framework or X Play app.

The repository's `stamp-modifications.cjs` is a source-only provenance supplement
added after that initial archive. Apply it to the unpacked `source` directory
before rebuilding: it inserts the modification date and summary into the five
modified files. The current Cloud script performs this step automatically.
Use the scripts from this repository with the archived sources; the original
archive and checksum are retained unchanged for traceability.

## Build

The production integration uses `Distribution/DecoderQA-2026-10-02/` scripts.
The Cloud entry point requires Xcode 27.0 build 27A266a and accepts
`CI_PRODUCT_PLATFORM=iOS`, `tvOS`, or `visionOS`; it rejects a beta toolchain.
It outputs only `Dependencies/VLCKit.xcframework` and never uploads an app.

For independently rebuilding or modifying the library, unpack the source bundle,
install the build tools listed in `build-cloud-decoder.sh`, and use the included
VLCKit `compile-cloud.sh` static-library wrapper with `-r -a aarch64 -v -e`
and the absolute path to the bundled `vlc` directory. Add `-t` for tvOS or `-i`
for visionOS. Then use `archive-decoder-framework.sh` with the source root and
the desired SDK. The Apple SDK/toolchain is obtained separately from Apple.
Keep the public VLCKit ABI compatible if substituting a modified framework.

X Play dynamically links VLCKit. X Play imposes no restriction on replacement
or reverse engineering of that component for debugging modifications allowed
by its license. Platform signing requirements are separate from library rights.
