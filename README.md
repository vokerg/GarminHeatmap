# Garmin Heatmap

Prototype Garmin Connect IQ data field for showing previously travelled GPS traces while a native Garmin Run or Hike activity is recording.

The field deliberately draws **no basemap**. Historical tracks have one visual weight: the screen answers only “have I been there?”. The current activity breadcrumb is drawn separately so a runner can see where the present exploration connects to old history.

## Current prototype

- Target: original Garmin fēnix 7 (`fenix7`, 260×260 MIP display).
- App type: full-screen Connect IQ data field inside Garmin's native activity.
- View: north-up, current position centred.
- History: generated Monkey C source containing simplified, quantized GPX tracks.
- Current activity: in-memory breadcrumb from `Activity.Info.currentLocation`.
- Default span: 1,200 metres across the screen.
- No phone, server, Strava API or runtime network dependency.

This phase is intentionally a watch-rendering feasibility spike. It is not yet a scalable world-history storage design.

## Data needed from you

Export **3–10 representative outdoor activities as individual GPX files**. A useful test set contains:

1. Several repeated runs on the same streets or trails.
2. Several intersecting routes.
3. One dense city route and one longer sparse route.
4. At least one file recorded near the place where you will test the watch.

GPX is preferred for this prototype because it requires no third-party parser. FIT can be added later. Keep the files private if they expose home or work; the repository ignores `samples/generated/`, but raw files should normally remain outside the repository entirely.

## Generate watch data

```bash
python3 tools/gpx_to_monkeyc.py ~/Downloads/run-*.gpx \
  --tolerance-m 8 \
  --max-points 3000 \
  --output source/HeatmapData.mc
```

The converter:

- reads all GPX track segments;
- simplifies each segment using Douglas–Peucker in local metre coordinates;
- quantizes latitude/longitude to integer degrees × 100,000;
- emits `source/HeatmapData.mc`;
- rejects datasets above the configured point guardrail.

For initial physical-device testing, start around 500–1,500 generated points. Increase only after observing memory and render behaviour.

## Build and run

Prerequisites:

- Garmin Connect IQ SDK Manager;
- a current Connect IQ SDK;
- a Garmin developer key;
- the `monkeyc` and `connectiq` commands available from the selected SDK.

Build for the fēnix 7 simulator:

```bash
monkeyc -f monkey.jungle \
  -d fenix7 \
  -o bin/GarminHeatmap.prg \
  -y /path/to/developer_key \
  -w

connectiq
monkeydo bin/GarminHeatmap.prg fenix7
```

For a physical watch, build an IQ package/export with the Garmin SDK tooling, install it, then add **Garmin Heatmap** as a one-field/full-screen page in the Run or Hike activity settings.

## Expected screen

- Thin dark-grey lines: historical tracks.
- White line: current-activity breadcrumb.
- White centre dot: current position.
- `N`: north-up orientation.
- Bottom-right ruler: current distance scale.
- `WAITING FOR GPS`: simulator/no-fix state; sample Copenhagen geometry remains visible around the fallback centre.

## Prototype limitations

- The scale is currently fixed at 1,200 m across.
- History is compiled into the application, not synchronized.
- The breadcrumb is not persisted after the activity.
- Segment rejection is coarse bounding-box culling, not full line clipping.
- Track deduplication and GPS-error normalization are not implemented.
- The generated dataset guardrail is heuristic and must be validated on hardware.
- CI tests the GPX converter only. Garmin's SDK is not redistributable through this repository, so Connect IQ compilation is currently local.

## Next engineering steps

1. Compile with the installed Garmin SDK and fix any SDK-version-specific Monkey C diagnostics.
2. Test update cadence, memory, battery and page-switch behaviour on a physical fēnix 7.
3. Add configurable near/medium/far scales.
4. Replace compiled global geometry with spatially chunked local storage.
5. Add a synchronization path—manual bundles first, optional API integration later.
6. Add geometry snapping/deduplication so repeated routes remain one equal-weight line.

## Privacy

Activity traces are sensitive location data. Do not commit personal GPX/FIT exports. For collaboration, provide sanitized files or tracks with home/work portions removed.
