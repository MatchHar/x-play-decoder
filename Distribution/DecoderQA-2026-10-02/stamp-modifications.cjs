// Add modification provenance without altering library behavior.
// Copyright (c) 2026 X Play contributors. LGPL-2.1-or-later.
const fs = require('node:fs');
const path = require('node:path');
const root = process.argv[2];
if (!root || !path.isAbsolute(root)) throw Error('An absolute decoder source root is required');
const changes = [
  ['vlc/contrib/src/ffmpeg/rules.mak', '#', 'Enable TrueHD/MLP decoding in the Apple configuration.'],
  ['vlc/modules/codec/libass.c', '//', 'Use the configured Apple fallback font while preserving ASS font priority.'],
  ['VLCKit/Sources/Core/VLCLibrary.m', '//', 'Register visionOS device and simulator static modules.'],
  ['VLCKit/VLCKit.xcodeproj/project.pbxproj', '//', 'Remove obsolete visionOS linker flags.'],
  ['VLCKit/compileAndBuildVLCKit.sh', '#', 'Distinguish arm64 device/simulator inputs and visionOS simulator packaging.']
];
for (const [relative, marker, change] of changes) {
  const file = path.join(root, relative);
  const text = fs.readFileSync(file, 'utf8');
  const notice = `${marker} X Play modification, 2026-10-02: ${change}\n`;
  if (text.includes(notice)) continue;
  // Preserve the shebang and Xcode project UTF-8 marker on the first line.
  const firstLine = text.indexOf('\n') + 1;
  const offset = text.startsWith('#!') || relative.endsWith('.pbxproj') ? firstLine : 0;
  fs.writeFileSync(file, text.slice(0, offset) + notice + text.slice(offset));
}
