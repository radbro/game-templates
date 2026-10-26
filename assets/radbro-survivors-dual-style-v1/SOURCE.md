# Radbro Survivors source assets

This version keeps both released art directions. See LICENSE.txt for game and source-template use. Publication approval is in publication.json. The original Radclaw draft records remain unchanged. Their historical review flags do not override this release approval.

provenance.json records every copied file, source run, byte count, and SHA-256 hash. The first 60 files are the game runtime. Source bytes were not changed during release.

Native hero: layered 64px paperdoll, rig radbro64-front-v2. Read native-hero/pack.json for anchors, clips, durations, slots, and layer order. source/native-hero contains all53 Aseprite masters for the parts, equipment, and presets. Native sentry, ground, and icons have Aseprite masters and author.lua under source/native-kit.

Illustrated hero: original Nano Banana four-phase output and prompt are under source/illustrated-hero. Sixteen original walk PNGs remain under illustrated-hero. This selected source uses canonical Radbro references. It does not use the later LPC/Sora guide trial. Enemy, ground, and idle PNGs retain the original image generation bytes. Their prompts are under source/. These illustrated files are editable raster images. They do not have layered Aseprite masters.

The idle atlas uses explicit unequal row bounds and per-frame floor anchors. Do not slice it into equal-height rows. Keep its pack.json rectangles and timings.

The template source ZIP includes this source directory. The playable Web export excludes source/ editor files. GDQuest art is not part of this pack. Its MIT code notice stays with the template.
