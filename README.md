# Garmin Heatmap

Garmin Heatmap is a Connect IQ data field for exploring new streets and trails while a normal Garmin Run or Hike activity is recording.

It deliberately draws **no basemap**. Instead, it shows every previously travelled GPS trace near the athlete's current position with equal visual weight. The screen answers one question:

> Have I already been there?

The current activity breadcrumb is drawn separately, allowing the runner or hiker to see how the route in progress connects to prior history. Garmin's native activity remains responsible for GPS recording, pause/resume, alerts, workouts, saving, and navigation screens.

## Product concept

The intended workflow is:

1. Export or otherwise obtain historical GPS activities.
2. Preprocess them into compact line geometry.
3. Load the resulting local history onto the watch.
4. Add Garmin Heatmap as a full-screen data page in Run or Hike.
5. During an activity, switch to the page to identify directions that appear unvisited.

This is an **exploration-history screen**, not a navigation map. It does not know whether an empty area contains a usable road, a river, private property, or no trail at all. Garmin's map or course screen should remain available on another activity page when navigation context is required.

## Prototype success criteria

The current prototype is successful if it demonstrates that, on a physical fēnix 7:

- historical lines remain legible on the 260×260 display;
- the current position and live breadcrumb update reliably;
- switching away from and back to the data page does not break state;
- a useful local dataset fits within Connect IQ memory limits;
- rendering does not noticeably interfere with activity recording;
- battery impact is acceptable for a normal run or hike;
- the display genuinely helps choose an unvisited direction.

Everything involving cloud synchronization, Strava, Garmin Connect, or global history is deliberately deferred until this watch-side experience is proven useful.

## Current prototype

- Target: original Garmin fēnix 7 (`fenix7`, 260×260 MIP display).
- App type: full-screen Connect IQ data field inside Garmin's native activity.
- View: north-up, current position centred.
- History: generated Monkey C source containing simplified, quantized GPX tracks.
- Current activity: in-memory breadcrumb from `Activity.Info.currentLocation`.
- Default span: 1,200 metres across the screen.
- No phone, server, Strava API, account, or runtime network dependency.

This phase is intentionally a watch-rendering feasibility spike. It is not yet a scalable world-history storage design.

## What is actually needed now

### Required from the tester

1. A local Garmin Connect IQ development environment:
   - Connect IQ SDK Manager;
   - a current Connect IQ SDK;
   - a Garmin developer key;
   - `monkeyc`, `monkeydo`, and `connectiq` available from the selected SDK.
2. Access to the original fēnix 7 simulator and, ideally, a physical fēnix 7.
3. Between **3 and 10 representative outdoor activities exported as individual GPX files**.
4. A short physical test run or hike in the same area as at least some of those GPX tracks.

### Recommended GPX sample set

A useful set contains:

- two or more repeated runs over the same streets or trails;
- several intersecting routes;
- one dense city route;
- one longer sparse route;
- at least one route near the physical-watch test area.

The files do not need to be committed or sent anywhere. They can remain entirely local. GPX is preferred for this prototype because it requires no third-party parser. FIT support can be added later if GPX proves insufficient.

### Not needed yet

- Strava API credentials;
- a Garmin Connect API integration;
- a backend or database;
- a phone companion application;
- complete lifetime activity history;
- public or sanitized sample data in the repository.

## Generate watch data

Run the converter against local GPX exports:

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

For initial physical-device testing, start around **500–1,500 generated points**. Increase only after observing memory and render behaviour.

## Build and run

Build for the fēnix 7 simulator:

```bash
mkdir -p bin

monkeyc -f monkey.jungle \
  -d fenix7 \
  -o bin/GarminHeatmap.prg \
  -y /path/to/developer_key \
  -w

connectiq
monkeydo bin/GarminHeatmap.prg fenix7
```

For a physical watch, build an IQ package/export with the Garmin SDK tooling, install it, then add **Garmin Heatmap** as a one-field/full-screen page in the Run or Hike activity settings.

## First validation session

Record these observations during the first simulator and watch tests:

- SDK and compiler version.
- Whether the project compiles without Monkey C changes.
- Peak memory shown by the simulator.
- Whether historical geometry is centred correctly.
- Whether the current marker moves correctly.
- Whether the breadcrumb persists while changing activity pages.
- Whether pause/resume creates incorrect line segments.
- Whether GPS loss or reacquisition creates jumps.
- Approximate battery consumption over a representative activity.
- Whether 1,200 m is a useful default span.
- Whether the screen helps identify an unexplored direction without a basemap.

Compiler errors, simulator screenshots, and device observations are more useful at this stage than additional architecture work.

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

The next steps depend on the physical test result:

1. Fix any SDK-version-specific Monkey C diagnostics.
2. Measure update cadence, memory, battery, and page-switch behaviour.
3. Add configurable near/medium/far scales.
4. Add geometry snapping and deduplication so repeated routes remain one equal-weight line.
5. Replace compiled geometry with spatially chunked local storage.
6. Add a manual bundle-loading workflow.
7. Only then evaluate optional automatic activity-source integrations.

## Privacy

Activity traces are sensitive location data. Do not commit personal GPX/FIT exports. Keep them outside the repository, or remove home/work portions before sharing sanitized examples.