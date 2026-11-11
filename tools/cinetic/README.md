# Cinetic authoring tool

[Cinetic](https://github.com/Leonxlnx/cinetic) is installed locally at `.runtime/tools/cinetic`, pinned to `f4bbfc844877891fe92279d47b7874fb44d485ae`. Its skill entry is `.runtime/tools/cinetic/skills/cinetic/SKILL.md`. The checkout is ignored by Git to keep the game repository small. On another machine, run `bash tools/cinetic/install.sh` from this repository.

Use it for **future trailers, motion graphics, and pre-rendered cutscenes**, with a separate film project and reviewed source footage. It is not a Godot cutscene editor or game runtime dependency. Read its `SKILL.md` and setup guide before authoring. Node 22+ and FFmpeg 6+ are present locally; the full Python/Chromium/Remotion authoring stack has **not** been installed or validated here. Remotion has a separate commercial-use license condition; check that license before choosing it for a production film. The alternative HyperFrames renderer has its own Apache-2.0 license.

Upstream code is MIT; the [license copy](LICENSE.upstream) is kept here. Film music, fonts, screenshots, rendered footage, and renderer dependencies require their own provenance and rights checks. No Cinetic output is part of the current game build.
