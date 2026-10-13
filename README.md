# Animal Switch

A playable portrait 3D animal-switching race, built in Godot 4.7.2 using the supplied animal models.

## Play

- Android: install `builds/AnimalSwitch.apk` on your Android phone. It is a debug-signed development build, suitable for sideloading.
- Windows: launch `builds/AnimalSwitch.exe`.
- Editor: import `game/project.godot` in Godot, then press F6/F5 to run.
- Tap the three animal buttons to switch. Movement and obstacle actions are automatic. On desktop, keys **1, 2, 3** also switch animals; **Escape** pauses.

Gentle mode stops safely at a wrong choice and hints at the right animal. Challenge mode adds a two-second setback and requires first place to advance. Progress and audio settings save locally. The 100-course campaign unlocks the next animal after every three completed races and keeps the unlock collection across restarts.

The visual update adds animated turquoise water with shoreline foam and swimming wakes, faceted breakable boulder walls, stepped canyon cliffs with rock strata, golden sand, and colored animals. Walls, logs, cliffs, falling debris, and climbing trees are short sections; water crossings are longer. Turtle shelters beneath its hard shell in level 6, Monkey climbs through trees in level 9, and level 10 combines Turtle, Monkey, and Otter. Each level still supplies exactly three suitable animals. Existing saves remain compatible.

The camera follows the player at a fixed offset, including vertical movement, and never changes framing to include opponents. One top progress line displays the positions of all three racers. When racers are close together, their icons separate vertically with pointers to their exact position on the same line.

Version 0.3.0 follows the supplied gameplay videos more closely: a diagonal rear view, larger racers, floating YOU/opponent labels, compact stone portrait buttons with a lime selection border, sandy running grooves, palms and shrubs, atmospheric backgrounds, and stronger foreground animal colors. Ordinary running speed varies by animal. Transformations remain available during obstacle crossings; a wrong choice stops safely in Gentle mode, and the correct choice continues from the same point. See `REFERENCE_MATCH.md` for the observed reference details and `tools/screenshots/animal-switch-preview.mp4` for a recorded gameplay preview.

Version 0.4.0 replaces all seven animals with models from `EverythingLibrary_Animals_002.blend`: Rhino, Snowy Owl, Green Frog, Otter, Elephant, Tortoise, and Chimpanzee. Natural vertex-painted colors are baked into portable albedo maps. Species-specific skeletal clips use diagonal quadruped gaits, slower elephant/tortoise steps, frog hops, owl wingbeats/gliding, otter paddling, and chimpanzee climbing. The first racer is explicitly the user and remains the camera target. The environment now includes layered woodland, curved foliage, bark detail, ferns, flowers, bank stones, and rolling terrain; chunked MultiMesh batches keep the added scenery efficient. The supplied Blender library remains unchanged.

## Project structure

Version 0.5.0 adds visible frog hop cycles with synchronized hind-leg extension, corrected vertical skeletal motion, body balance for walking animals, owl flight bob, and otter swim roll with spray. Rocks use gravity-driven trajectories, spin, damped bounces and settling; tortoise shells deflect nearby falling stones. Rock surfaces have mineral grain and cliff strata, while water has wave-aligned normals and a shallow-edge color gradient. These are lightweight, scripted physical effects: obstacle success remains controlled by the animal's ability for predictable play.

Version 0.6.0 prepares the complete 50-animal library from `EverythingLibrary_Animals_002.blend`. Every animal has a normalized forward-facing GLB, portrait, rig, species/family movement clips, asymmetric coat or skin color treatment, and baked albedo, normal, roughness, and ambient-occlusion maps. The home screen includes an offline `Meet all 50 animals` viewer with previous/next navigation and a clip picker. The approved roster and source-to-asset mapping are in `tools/roster50.py` and `game/assets/animals/roster.json`.

Version 0.7.0 expands the campaign to 100 deterministic levels. Course lengths vary from roughly 220 to 580 world units, obstacle sections range from 3 to 20, and every generated team has a matching ability for every obstacle. River and jungle chapters alternate, with quick-switch patterns on selected levels. Environment geometry is denser (subdivided terrain, smoother trees and rocks) and road, soil, bark, and scenery materials now use layered procedural detail, normal variation, roughness, and distance haze for a richer semi-realistic finish while staying within the Compatibility renderer.

Version 0.8.0 refreshes all 50 animation exports. Locomotion now uses eased curves, vertical body settling on contact, post-impact compression for heavy animals, near-planted feet during stance, diagonal limb timing, spine sway, tail/wing follow-through, and a true frog airborne arc. River sections now include layered animated waterfall sheets with noisy flow and foamy plunge pools.

Version 0.9.0 gives every roster animal an explicit gait assignment and individual cadence/body-motion profile. The 50 exports now distinguish lateral and diagonal walks, trotting, pacing, galloping, bounding, knuckle-walking, sprawling reptile motion, flight, swimming, and slow shell-bearing steps. Leg cycles separate stance, swing recovery, knee fold, and foot lift; torso, head, tail, trunk, and wing motion follow the animal's gait. The frog uses a staged crouch, hind-leg push, airborne tuck, forelimb landing, and recovery. Its game root stays planted so the rig visibly articulates instead of bouncing as one rigid statue. These are tuned skeletal animations built on the supplied static meshes, not motion-capture recordings.

The final rig pass removes the duplicate upright bear meshes that were accidentally being combined with the quadruped meshes in the source library. Brown Bear and Black Bear now export as clean four-legged models, and torso weights use a dedicated spine segment so the upper body and legs deform together instead of appearing rigid and soft separately.

The frog export uses the library's proper `RedEyedTreeFrog` mesh; the original `GreenFrog` entry was a long-tailed salamander-like asset. It keeps the Green Frog game ID, green palette, jump ability, and frog-specific hop clips.

- `game/`: editable game source, models, portraits, menu background, and export presets.
- `tools/prepared_library_animals/`: current editable Blender copies, skeletons, animations, and baked albedo textures.
- `tools/prepare_library_animals.py`: repeatable non-destructive preparation for the current animal library.
- `EverythingLibrary_Animals_002.blend`: original current animal library, preserved.
- `tools/previous_animals_v03/`: backup of the previous game-ready animals.
- `tools/prepared_animals/`: earlier editable animal preparation, retained.
- `3d_model_assets/`: original supplied assets, preserved.
- `tools/prepare_animals.py`: earlier background Blender preparation and export.
- `tools/run_checks.ps1`: gameplay checks, UI checks, and screenshot capture.
- `tools/build.ps1`: Android or Windows export using the locally installed engine.

## Build and validation

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_checks.ps1 -Mode test
powershell -ExecutionPolicy Bypass -File tools/build.ps1 -Platform Android
powershell -ExecutionPolicy Bypass -File tools/build.ps1 -Platform Windows
```

Android SDK, OpenJDK, templates, and the development keystore are under `tools/android/`. The export presets use those local templates. Godot's Android SDK and Java paths are configured by `tools/setup_android.ps1`. These dependencies are ignored by Git; retain them locally or rerun setup on another machine.

See `VALIDATION.md` for the test record and hardware testing limits. The Android build supports Android 7.0 and newer (API 24+).

## Artwork and future release

Gameplay uses original scenery and all 50 prepared animal models from the supplied Everything Library pack. Models have natural painted colors, skeleton-driven idle, locomotion, ability, and celebration clips, and consistent forward alignment. Water, road, bark, soil, rock, and foliage materials use procedural Godot shaders. Visual previews are in `tools/screenshots/visual-*.png`; regenerate them with `game/tests/capture_visuals.gd`. Animation pose sheets are `tools/screenshots/animal-motion-run.jpg` and `animal-motion-ability.jpg`. The home backdrop was generated with the built-in imagegen tool; its exact prompt is recorded in `tools/image_prompt.txt`, and its project asset is `game/assets/ui/jungle_menu.png`.

This version is offline, with no ads, accounts, purchases, or analytics. A monetization phase is deferred: choose a parent-facing model, then separately implement its purchase flow and release requirements. Store publishing, a production signing key, and an AAB release are outside this development build. Asset usage rights remain supplied by the owner.
