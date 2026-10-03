# X Play decoder source and build materials

Corresponding open-source library materials for X Play 3.02 (72). No proprietary
application code, media, credentials, signing files, or playback logs are included.
Source publication is not evidence of App Store approval or physical-device testing.

## Sources and modifications

- VLCKit: `5d3535a664e7815765a5cee40d9b22527d7299cc`, from
  https://code.videolan.org/videolan/VLCKit
- VLC: `c9628afc4b221b171ec2d9e028782b9eb1247426`, from
  https://code.videolan.org/videolan/vlc, with its 20 VLCKit-supplied patches,
  followed by `vlc-truehd.patch`, `vlc-ass-fallback.patch`, and `vlc-apple-output.patch`.
- FFmpeg 8.1.2 source SHA-256:
  `464beb5e7bf0c311e68b45ae2f04e9cc2af88851abb4082231742a74d97b524c`.
- Other dependencies and licenses are in VLC `contrib/src`; their source archives
  and a complete SHA-256 source inventory accompany the full source bundle.

Modifications dated 2026-10-02 enable TrueHD/MLP decoding, preserve ASS fallback
font selection, correct Apple arm64 architecture and visionOS module registration,
and package iOS/tvOS 18+ and visionOS 2+ framework slices. Modifications dated
2026-10-03 supply PCM **per-sample** timing to AVSampleBufferAudioRenderer and
flush the video sample-buffer layer only when Apple explicitly requires recovery.
Modified files carry their modification notice. Components retain their upstream
licenses; VLCKit/libVLC are LGPL-2.1-or-later. See COPYING.LGPL-2.1 and the full
upstream notices. No warranty is provided.

## Complete corresponding source

https://github.com/MatchHar/x-play-decoder/releases/tag/xplay-3.02-72

The release's `xplay-decoder-3.02-72-source.tar.gz` contains patched VLCKit and VLC
sources, dependency source archives, scripts, notices, and SOURCE-SHA256SUMS.txt.
The checksum is supplied separately. No prebuilt app or framework is distributed.
Earlier release archives remain unchanged.

## Build and replacement

The production `Distribution/DecoderQA-2026-10-02/build-cloud-decoder.sh` rebuilds
the pinned sources using Xcode 27.0 build 27A266a. Cloud platforms iOS, tvOS,
xrOS/visionOS are supported; beta toolchains are rejected. It produces only
Dependencies/VLCKit.xcframework and does not upload an app.

For an independent rebuild, unpack the source bundle, install the tools listed
in the build script, and run the included VLCKit compile-cloud.sh wrapper with
`-r -a aarch64 -v -e` followed by the absolute VLC source path. Add `-t` for tvOS
or `-i` for visionOS. Run archive-decoder-framework.sh with the source root and
desired SDK to package the library. Obtain Apple's SDK/toolchain separately.
Keep the public VLCKit ABI compatible when substituting a modified framework.

X Play dynamically links VLCKit and imposes no restriction on replacement or
reverse engineering of that library for debugging modifications allowed by its
license. Platform signing requirements are separate from these library rights.
